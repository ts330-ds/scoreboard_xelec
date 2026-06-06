import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/local/history_local_store.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/local/hr_reading_hive.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/local/rr_sample_hive.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class BleFetchDemoScreen extends StatefulWidget {
  const BleFetchDemoScreen({super.key});

  @override
  State<BleFetchDemoScreen> createState() => _BleFetchDemoScreenState();
}

class _BleFetchDemoScreenState extends State<BleFetchDemoScreen> {
  late final HeartBleCubit _bleCubit;
  late final BleFetchRangeCubit _fetchCubit;

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 10));
  DateTime _toDate = DateTime.now();

  String _statusMessage = '';

  List<HrReadingHive> _hrReadings = [];
  List<RrSampleHive> _rrSamples = [];

  // Only used for Fetch All (still uses HeartBleCubit directly)
  bool _isFetchingAll = false;
  StreamSubscription<HeartBleState>? _fetchAllSub;
  Timer? _fetchAllTimeout;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _bleCubit = sl<HeartBleCubit>();
    _fetchCubit = sl<BleFetchRangeCubit>();
    _loadFromHive();
  }

  @override
  void dispose() {
    _fetchAllSub?.cancel();
    _fetchAllTimeout?.cancel();
    _settleTimer?.cancel();
    _fetchCubit.close();
    super.dispose();
  }

  Future<void> _loadFromHive() async {
    final store = HistoryLocalStore.instance;
    await store.open();
    final hrMaps = store.getAllHr();
    final rrMaps = store.getAllRr();

    setState(() {
      _hrReadings = hrMaps.map((m) => HrReadingHive.fromMap(m)).toList()
        ..sort((a, b) => a.stamp.compareTo(b.stamp));
      _rrSamples = rrMaps.map((m) => RrSampleHive.fromMap(m)).toList()
        ..sort((a, b) => a.stamp.compareTo(b.stamp));
    });
  }

  // ── Fetch Range — uses BleFetchRangeCubit ──

  Future<void> _startFetchRange() async {
    _fetchCubit.fetchRange(from: _fromDate, to: _toDate);
  }

  Future<void> _onRangeFetchComplete(BleFetchRangeState fetchState) async {
    final store = HistoryLocalStore.instance;
    await store.open();
    final hrSaved = await store.upsertHrChunk(fetchState.hrData);
    final rrSaved = await store.upsertRrChunk(fetchState.rrData);
    await _loadFromHive();

    if (mounted) {
      setState(() {
        _statusMessage =
            '${fetchState.message} | Saved HR: $hrSaved, RR: $rrSaved';
      });
    }
  }

  // ── Fetch All — uses HeartBleCubit directly ──

  Future<void> _startFetchAll() async {
    if (!_bleCubit.state.isConnected) {
      setState(() => _statusMessage = 'BLE device not connected!');
      return;
    }

    setState(() {
      _isFetchingAll = true;
      _statusMessage = 'Fetching ALL data from device...';
    });

    int lastHrLen = 0;
    int lastRrLen = 0;
    bool dataCleared = false;

    _fetchAllSub?.cancel();
    _fetchAllSub = _bleCubit.stream.listen((state) {
      if (!_isFetchingAll) return;

      if (state.historyHrData.isEmpty && state.status.contains('yncing')) {
        dataCleared = true;
        lastHrLen = 0;
        lastRrLen = 0;
        if (mounted) setState(() => _statusMessage = 'Syncing all data...');
        return;
      }

      final hrNow = state.historyHrData.length;
      final rrNow = state.historyRrData.length;

      if (hrNow != lastHrLen || rrNow != lastRrLen) {
        lastHrLen = hrNow;
        lastRrLen = rrNow;
        if (mounted) {
          setState(() => _statusMessage = 'Receiving... HR: $hrNow, RR: $rrNow');
        }
        _settleTimer?.cancel();
        _settleTimer = Timer(const Duration(seconds: 10), () {
          if (_isFetchingAll && mounted) _onFetchAllComplete();
        });
      }

      if (state.status == 'Sync complete' && dataCleared) {
        _settleTimer?.cancel();
        _settleTimer = Timer(const Duration(seconds: 3), () {
          if (_isFetchingAll && mounted) _onFetchAllComplete();
        });
      }
    });

    _bleCubit.syncAllHistory(force: true);

    _fetchAllTimeout?.cancel();
    _fetchAllTimeout = Timer(const Duration(seconds: 180), () {
      if (_isFetchingAll && mounted) _onFetchAllComplete(timedOut: true);
    });
  }

  Future<void> _onFetchAllComplete({bool timedOut = false}) async {
    if (!_isFetchingAll) return;
    _isFetchingAll = false;
    _fetchAllSub?.cancel();
    _fetchAllTimeout?.cancel();
    _settleTimer?.cancel();

    final hrData = _bleCubit.state.historyHrData;
    final rrData = _bleCubit.state.historyRrData;

    final store = HistoryLocalStore.instance;
    await store.open();
    final hrSaved = await store.upsertHrChunk(hrData);
    final rrSaved = await store.upsertRrChunk(rrData);

    await _loadFromHive();

    if (mounted) {
      setState(() {
        _statusMessage = timedOut
            ? 'Timeout! HR: ${hrData.length} found, $hrSaved saved | RR: ${rrData.length} found, $rrSaved saved'
            : 'All done! HR: ${hrData.length} found, $hrSaved saved | RR: ${rrData.length} found, $rrSaved saved';
      });
    }
  }

  // ── Helpers ──

  Future<void> _pickDateTime(bool isFrom) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isFrom ? _fromDate : _toDate),
    );
    if (time == null || !mounted) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _clearHiveData() async {
    final store = HistoryLocalStore.instance;
    await store.open();
    await store.clearAll();
    await _loadFromHive();
    setState(() => _statusMessage = 'Hive data cleared!');
  }

  bool get _isBusy => _isFetchingAll || _fetchCubit.state.isSyncing;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('BLE Fetch Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHiveData,
            tooltip: 'Clear Hive',
          ),
        ],
      ),
      body: BlocListener<BleFetchRangeCubit, BleFetchRangeState>(
        bloc: _fetchCubit,
        listener: (context, fetchState) {
          if (fetchState.status == FetchRangeStatus.syncing) {
            setState(() => _statusMessage = fetchState.message);
          } else if (fetchState.status == FetchRangeStatus.complete) {
            _onRangeFetchComplete(fetchState);
          } else if (fetchState.status == FetchRangeStatus.error) {
            setState(() => _statusMessage = fetchState.message);
          }
        },
        child: Column(
          children: [
            // ── BLE Status ──
            BlocBuilder<HeartBleCubit, HeartBleState>(
              bloc: _bleCubit,
              buildWhen: (p, c) => p.isConnected != c.isConnected,
              builder: (context, state) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color:
                      state.isConnected ? Colors.green.shade50 : Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(
                        state.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: state.isConnected ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isConnected
                            ? 'Device Connected'
                            : 'Device Not Connected',
                        style: TextStyle(
                          color: state.isConnected
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Time Range Pickers ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DateTimeRow(
                    label: 'From',
                    value: fmt.format(_fromDate),
                    onTap: () => _pickDateTime(true),
                  ),
                  const SizedBox(height: 12),
                  _DateTimeRow(
                    label: 'To',
                    value: fmt.format(_toDate),
                    onTap: () => _pickDateTime(false),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: BlocBuilder<BleFetchRangeCubit,
                              BleFetchRangeState>(
                            bloc: _fetchCubit,
                            buildWhen: (p, c) => p.isSyncing != c.isSyncing,
                            builder: (context, fetchState) {
                              final busy = fetchState.isSyncing || _isFetchingAll;
                              return ElevatedButton.icon(
                                onPressed: busy ? null : _startFetchRange,
                                icon: fetchState.isSyncing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: Text(
                                  fetchState.isSyncing
                                      ? 'Fetching...'
                                      : 'Fetch (Range)',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isBusy ? null : _startFetchAll,
                            icon: _isFetchingAll
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_download),
                            label: Text(
                              _isFetchingAll ? 'Fetching...' : 'Fetch All',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('!')
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Stats Bar ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                children: [
                  _StatChip(label: 'HR Readings', count: _hrReadings.length),
                  const SizedBox(width: 16),
                  _StatChip(label: 'RR Samples', count: _rrSamples.length),
                ],
              ),
            ),

            // ── Data Tabs ──
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.subtext,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: 'Heart Rate'),
                        Tab(text: 'RR Intervals'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildHrList(),
                          _buildRrList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHrList() {
    if (_hrReadings.isEmpty) {
      return const Center(
        child: Text('No HR data in Hive',
            style: TextStyle(color: AppColors.subtext)),
      );
    }
    return ListView.builder(
      itemCount: _hrReadings.length,
      itemBuilder: (context, index) {
        final r = _hrReadings[index];
        final time = DateTime.fromMillisecondsSinceEpoch(
          r.stamp > 9999999999 ? r.stamp : r.stamp * 1000,
        );
        return ListTile(
          dense: true,
          leading: const Icon(Icons.favorite, color: Colors.red, size: 20),
          title: Text(
            '${r.heartRate} bpm',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            DateFormat('dd MMM, hh:mm:ss a').format(time),
            style: const TextStyle(fontSize: 12, color: AppColors.subtext),
          ),
          trailing: Text(
            '#${index + 1}',
            style: const TextStyle(fontSize: 11, color: AppColors.subtext),
          ),
        );
      },
    );
  }

  Widget _buildRrList() {
    if (_rrSamples.isEmpty) {
      return const Center(
        child: Text('No RR data in Hive',
            style: TextStyle(color: AppColors.subtext)),
      );
    }
    return ListView.builder(
      itemCount: _rrSamples.length,
      itemBuilder: (context, index) {
        final r = _rrSamples[index];
        final time = DateTime.fromMillisecondsSinceEpoch(
          r.stamp > 9999999999 ? r.stamp : r.stamp * 1000,
        );
        return ListTile(
          dense: true,
          leading: const Icon(Icons.timeline, color: Colors.blue, size: 20),
          title: Text(
            '${r.value} ms',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            DateFormat('dd MMM, hh:mm:ss a').format(time),
            style: const TextStyle(fontSize: 12, color: AppColors.subtext),
          ),
          trailing: Text(
            '#${index + 1}',
            style: const TextStyle(fontSize: 11, color: AppColors.subtext),
          ),
        );
      },
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateTimeRow(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.subtext.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.subtext, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.subtext),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  const _StatChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
