import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/entity/active_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/usecase/get_active_tasks_usecase.dart';
import 'package:xelex_esp/service/network/network_reconnect_notifier.dart';
import 'package:xelex_esp/service/socket/reconnect_controller.dart';
import 'package:xelex_esp/service/socket/team_live_socket_service.dart';
import 'coach_team_live_state.dart';

/// Coach "Whole Team" live dashboard cubit.
///
/// Approach (NO backend change): active-tasks REST list se saare in-progress
/// athletes ke cards seed karta hai, phir har task ko proven `watch_task_results`
/// se watch karke `live_result_update` (task_id-tagged) ko card pe map karta hai.
/// Naye/khatam sessions detect karne ke liye list ko periodically poll karta hai.
class CoachTeamLiveCubit extends Cubit<CoachTeamLiveState>
    with WidgetsBindingObserver {
  final TeamLiveSocketService _socketService;
  final GetActiveTasksUseCase _getActiveTasks;
  final SharedPreferences _prefs;

  // Stale fallback: ~30s tak update na aaye to card grey.
  static const _staleThreshold = Duration(seconds: 30);
  static const _staleCheckInterval = Duration(seconds: 5);
  // Naye/khatam session detect karne ke liye active-tasks list poll.
  static const _pollInterval = Duration(seconds: 45);
  // watch_task_results ack (watching_task) na aaye to re-emit.
  static const _watchRetryInterval = Duration(milliseconds: 800);
  // Socket drop hone par turant "Reconnecting" banner mat dikhao. Aksar server
  // watched-athlete crash pe coach ko bhi gira deta hai par 2-3s me khud
  // reconnect ho jaata hai — is grace ke andar recover ho jaye to banner
  // flash hi na ho. Isse zyada der lage tabhi banner dikhta hai.
  static const _bannerDelay = Duration(seconds: 3);
  // Ek task ko itni baar se zyada watch try mat karo — agar server kabhi
  // watching_task ack na bheje (e.g. "not authorized"), to forever spam na ho.
  static const _maxWatchAttempts = 8;
  static const _maxPages = 20;

  bool _isWatching = false;
  bool _isBackgrounded = false;
  final ReconnectController _reconnect = ReconnectController(tag: 'TEAM RECONNECT');
  StreamSubscription<void>? _netSub;
  Timer? _staleTimer;
  Timer? _pollTimer;
  Timer? _watchRetryTimer;
  Timer? _bannerDelayTimer;
  bool _refreshing = false;

  // Jin tasks ka watching_task ack mil chuka hai.
  final Set<int> _confirmed = {};
  // Per-task watch attempt count + jin par give-up kar diya (ack hi nahi aaya).
  final Map<int, int> _watchAttempts = {};
  final Set<int> _watchGaveUp = {};

  CoachTeamLiveCubit({
    required TeamLiveSocketService socketService,
    required GetActiveTasksUseCase getActiveTasks,
    required SharedPreferences prefs,
  })  : _socketService = socketService,
        _getActiveTasks = getActiveTasks,
        _prefs = prefs,
        super(const CoachTeamLiveState()) {
    WidgetsBinding.instance.addObserver(this);
    _setupCallbacks();
    _netSub = NetworkReconnectNotifier.instance.onNetworkRestored.listen((_) {
      if (isClosed || !_isWatching || state.isAuthFailure) return;
      if (!_socketService.isConnected) {
        debugPrint('[TEAM CUBIT] network restored — forcing retry');
        retryConnectionManually();
      }
    });
  }

  // ── App Lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _onAppPaused();
    }
  }

  void _onAppPaused() {
    _isBackgrounded = true;
    _reconnect.cancel();
  }

  void _onAppResumed() {
    _isBackgrounded = false;
    if (!_isWatching || state.isAuthFailure) return;
    if (!_socketService.isConnected) {
      debugPrint('[LIFECYCLE] Team socket dropped — reconnecting');
      _reconnect.reset();
      emit(state.copyWith(
        status: CoachTeamLiveStatus.reconnecting,
        isReconnectExhausted: false,
        reconnectAttempt: 0,
      ));
      _connect();
    } else {
      // Resume pe list bhi refresh kar lo — ho sakta hai naye sessions aaye hon.
      _refreshActiveTasks();
    }
  }

  void _setupCallbacks() {
    _socketService.onWatchingTask = (taskId) {
      _confirmed.add(taskId);
    };

    _socketService.onLiveUpdate = (taskId, reading) {
      if (isClosed) return;
      final existing = state.cards[taskId];
      // Sirf un tasks ke updates dikhao jinka card hai (naam wagaira list se aata hai).
      if (existing == null) return;
      final cards = Map<int, TeamAthleteCard>.from(state.cards);
      cards[taskId] = existing.applyReading(reading);
      emit(state.copyWith(cards: cards));
    };

    _socketService.onAthleteStopped = (taskId) {
      if (isClosed || !state.cards.containsKey(taskId)) return;
      final cards = Map<int, TeamAthleteCard>.from(state.cards)..remove(taskId);
      _forgetTask(taskId);
      _socketService.unwatchTask(taskId);
      emit(state.copyWith(cards: cards));
    };

    _socketService.onAthleteConnectionLost = (taskId) {
      if (isClosed) return;
      final existing = state.cards[taskId];
      if (existing == null || existing.isOffline) return;
      final cards = Map<int, TeamAthleteCard>.from(state.cards);
      cards[taskId] = existing.copyWith(isOffline: true);
      emit(state.copyWith(cards: cards));
    };

    _socketService.onDisconnected = () {
      _resetWatchTracking();
      _watchRetryTimer?.cancel();
      _watchRetryTimer = null;
      // `connecting` bhi include — warna pehla connect fail hone par kabhi
      // reconnect schedule hi nahi hota aur screen "Connecting…" pe atak jaati.
      if (!isClosed &&
          _isWatching &&
          (state.status == CoachTeamLiveStatus.watching ||
              state.status == CoachTeamLiveStatus.reconnecting ||
              state.status == CoachTeamLiveStatus.connecting) &&
          !state.isAuthFailure) {
        debugPrint('[TEAM CUBIT] Socket dropped — scheduling reconnect');
        // Banner turant nahi — grace ke baad hi (agar tab tak reconnect na ho).
        _scheduleBannerAfterDelay();
        if (!_isBackgrounded) _scheduleReconnect();
      }
    };

    _socketService.onError = (message) {
      if (isClosed) return;
      if (state.status == CoachTeamLiveStatus.watching ||
          state.status == CoachTeamLiveStatus.reconnecting) {
        return;
      }
      emit(state.copyWith(errorMessage: message));
    };

    _socketService.onAuthFailure = (message) {
      _reconnect.cancel();
      if (!isClosed) {
        emit(state.copyWith(
          status: CoachTeamLiveStatus.error,
          errorMessage: message,
          isAuthFailure: true,
        ));
      }
    };

    // "Not authenticated yet" — race. watch-retry timer waise bhi re-emit karega.
    _socketService.onNotReady = () {
      if (isClosed || !_isWatching) return;
      _ensureWatchRetryTimer();
    };
  }

  // ── Socket connect ────────────────────────────────────────────────────────

  void _connect() {
    final token = _prefs.getString(PrefKeys.coachToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) {
      emit(state.copyWith(
        status: CoachTeamLiveStatus.error,
        errorMessage: 'Missing session — please log in again',
      ));
      return;
    }
    _socketService.connect(baseUrl, token, onConnected: () {
      if (isClosed) return;
      _resetWatchTracking();
      _reconnect.reset();
      // Reconnect ho gaya — pending banner-delay cancel, banner flash na ho.
      _bannerDelayTimer?.cancel();
      _bannerDelayTimer = null;
      emit(state.copyWith(
        status: CoachTeamLiveStatus.watching,
        reconnectAttempt: 0,
        isReconnectExhausted: false,
      ));
      // Connect hote hi list refresh + saare known tasks watch karo.
      _refreshActiveTasks();
      _ensureWatchRetryTimer();
    });
  }

  // Known cards me se jo confirm nahi hue unke liye watch_task_results re-emit
  // karta rehta hai jab tak ack na mile. Kuch pending na ho to khud cancel.
  void _ensureWatchRetryTimer() {
    if (_watchRetryTimer != null) return;
    _watchRetryTimer = Timer.periodic(_watchRetryInterval, (_) {
      if (isClosed || !_isWatching || !_socketService.isConnected) return;
      final pending = state.cards.keys
          .where((id) => !_confirmed.contains(id) && !_watchGaveUp.contains(id))
          .toList();
      if (pending.isEmpty) {
        _watchRetryTimer?.cancel();
        _watchRetryTimer = null;
        return;
      }
      for (final taskId in pending) {
        final attempts = (_watchAttempts[taskId] ?? 0) + 1;
        _watchAttempts[taskId] = attempts;
        if (attempts > _maxWatchAttempts) {
          // Server kabhi ack nahi de raha — is task ko chhod do (spam roko).
          debugPrint('[TEAM CUBIT] giving up watch for task $taskId (no ack)');
          _watchGaveUp.add(taskId);
          continue;
        }
        _socketService.watchTask(taskId);
      }
    });
  }

  // Reconnect/fresh-connect pe watch tracking reset — sab dobara confirm hoga.
  void _resetWatchTracking() {
    _confirmed.clear();
    _watchAttempts.clear();
    _watchGaveUp.clear();
  }

  // Ek task ka saara watch-tracking bhula do (card hatne par).
  void _forgetTask(int taskId) {
    _confirmed.remove(taskId);
    _watchAttempts.remove(taskId);
    _watchGaveUp.remove(taskId);
  }

  // ── Active tasks (REST) → seed/reconcile cards ──────────────────────────────

  Future<void> _refreshActiveTasks() async {
    if (_refreshing || isClosed || !_isWatching) return;
    _refreshing = true;
    try {
      final tasks = await _fetchAllActiveTasks();
      if (tasks == null || isClosed) return;

      final freshIds = tasks.map((t) => t.taskId).toSet();
      final cards = Map<int, TeamAthleteCard>.from(state.cards);
      var changed = false;

      // Naye sessions → seed + watch.
      for (final t in tasks) {
        if (!cards.containsKey(t.taskId)) {
          cards[t.taskId] = TeamAthleteCard.seed(t);
          changed = true;
          if (_socketService.isConnected) _socketService.watchTask(t.taskId);
        }
      }
      // Jo ab in-progress list me nahi → session khatam, hata do.
      for (final taskId in cards.keys.toList()) {
        if (!freshIds.contains(taskId)) {
          cards.remove(taskId);
          _forgetTask(taskId);
          _socketService.unwatchTask(taskId);
          changed = true;
        }
      }

      if (changed) {
        emit(state.copyWith(cards: cards));
        _ensureWatchRetryTimer();
      }
    } finally {
      _refreshing = false;
    }
  }

  // Saare pages fetch karke complete in-progress list deta hai (null = failure).
  Future<List<ActiveTaskEntity>?> _fetchAllActiveTasks() async {
    final all = <ActiveTaskEntity>[];
    var page = 1;
    var total = 0;
    while (page <= _maxPages) {
      final result = await _getActiveTasks(status: 'in_progress', page: page).run();
      final ok = result.fold((_) => false, (data) {
        all.addAll(data.tasks);
        total = data.totalRecords;
        return true;
      });
      if (!ok) return all.isEmpty ? null : all; // partial > nothing
      if (all.length >= total || total == 0) break;
      page++;
    }
    return all;
  }

  void _startStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer.periodic(_staleCheckInterval, (_) {
      if (isClosed || state.cards.isEmpty) return;
      final now = DateTime.now();
      var changed = false;
      final cards = Map<int, TeamAthleteCard>.from(state.cards);
      for (final entry in cards.entries) {
        final card = entry.value;
        if (card.isOffline) continue;
        // Reading aayi thi to uska time; warna seed hone ka time. Dono me se jo
        // bhi ho, stale-threshold se purana hai to card grey. `seededAt` fallback
        // us case ke liye zaroori hai jab athlete app kill kar chuka ho par
        // backend task ko in_progress dikhata rahe — card seed to hota hai par
        // kabhi live reading nahi aati (warna forever "live, HR --" atka rehta).
        final ref = card.lastUpdate ?? card.seededAt;
        if (now.difference(ref) >= _staleThreshold) {
          cards[entry.key] = card.copyWith(isOffline: true);
          changed = true;
        }
      }
      if (changed) emit(state.copyWith(cards: cards));
    });
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshActiveTasks());
  }

  // ── Reconnect ───────────────────────────────────────────────────────────────

  // Grace-period baad hi "Reconnecting" banner dikhao — quick self-heal wale
  // drops par flash na ho. Pehle se timer chalu ya banner dikh raha ho to
  // dobara reset mat karo (warna flapping drop banner ko forever aage khiskata
  // rahega aur woh kabhi dikhega hi nahi).
  void _scheduleBannerAfterDelay() {
    if (state.status == CoachTeamLiveStatus.reconnecting) return;
    if (_bannerDelayTimer != null) return;
    _bannerDelayTimer = Timer(_bannerDelay, () {
      _bannerDelayTimer = null;
      if (isClosed || !_isWatching) return;
      if (!_socketService.isConnected && !state.isAuthFailure) {
        emit(state.copyWith(status: CoachTeamLiveStatus.reconnecting));
      }
    });
  }

  void _scheduleReconnect() {
    _reconnect.schedule(
      onAttempt: (attempt) {
        if (isClosed || !_isWatching) return;
        if (_socketService.isConnected) return;
        debugPrint('[TEAM CUBIT] Reconnect attempt #$attempt');
        emit(state.copyWith(reconnectAttempt: attempt));
        _connect();
      },
      onExhausted: () {
        if (isClosed) return;
        debugPrint('[TEAM CUBIT] Reconnect budget exhausted');
        emit(state.copyWith(isReconnectExhausted: true));
      },
    );
  }

  void retryConnectionManually() {
    if (isClosed || !_isWatching) return;
    _reconnect.reset();
    emit(state.copyWith(
      status: CoachTeamLiveStatus.reconnecting,
      isReconnectExhausted: false,
      reconnectAttempt: 0,
    ));
    _connect();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  // Coach jab team screen open kare.
  void startWatching() {
    _isWatching = true;
    _reconnect.reset();
    emit(const CoachTeamLiveState(status: CoachTeamLiveStatus.connecting));
    _startStaleTimer();
    _startPollTimer();
    // List turant seed kar do (socket se independent), phir socket connect.
    _refreshActiveTasks();
    _connect();
  }

  // Coach jab screen chhode.
  void stopWatching() {
    _isWatching = false;
    _resetWatchTracking();
    _reconnect.cancel();
    _staleTimer?.cancel();
    _staleTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _watchRetryTimer?.cancel();
    _watchRetryTimer = null;
    _bannerDelayTimer?.cancel();
    _bannerDelayTimer = null;
    for (final taskId in state.cards.keys) {
      _socketService.unwatchTask(taskId);
    }
    _socketService.disconnect();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnect.dispose();
    _netSub?.cancel();
    _staleTimer?.cancel();
    _pollTimer?.cancel();
    _watchRetryTimer?.cancel();
    _bannerDelayTimer?.cancel();
    _socketService.dispose();
    return super.close();
  }
}
