import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/screen/record_data_screen.dart';

/// Debug/diagnostic screen: fires the READ-ONLY `previewHrRecords()` and shows
/// the raw HR record HEADERS (one per session), each with its session-start
/// time. Tapping a record opens [RecordDataScreen] with that record's readings.
///
/// Unlike `syncAllHistory`, this does NOT fetch per-record data, persist to
/// SQLite, or push to the server — purely for inspecting device records.
class HistoryRecordsScreen extends StatelessWidget {
  const HistoryRecordsScreen({super.key});

  /// Opens the screen while preserving the caller's existing [HeartBleCubit]
  /// (records live on that cubit's state — a fresh instance would be empty).
  static Route<void> route(BuildContext context) {
    final cubit = context.read<HeartBleCubit>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const HistoryRecordsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _RecordsView();
  }
}

class _RecordsView extends StatefulWidget {
  const _RecordsView();

  @override
  State<_RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<_RecordsView> {
  // Preview path `status` ko "Syncing" set nahi karta — record headers aane tak
  // (ya timeout) ye local flag spinner dikhata hai.
  bool _loading = false;
  Timer? _loadingTimeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPreview());
  }

  void _requestPreview() {
    final cubit = context.read<HeartBleCubit>();
    if (!cubit.state.isConnected) return;
    setState(() => _loading = true);
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _loading = false);
    });
    cubit.previewHrRecords();
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('History Records',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        actions: [
          BlocBuilder<HeartBleCubit, HeartBleState>(
            buildWhen: (p, c) => p.isConnected != c.isConnected,
            builder: (context, state) {
              final connected = state.isConnected;
              return IconButton(
                tooltip: connected ? 'Reload records' : 'Connect a device first',
                onPressed: connected ? _requestPreview : null,
                icon: Icon(Icons.sync,
                    color: connected ? AppColors.primary : AppColors.textHint),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<HeartBleCubit, HeartBleState>(
        listenWhen: (p, c) => p.previewHrRecords != c.previewHrRecords,
        listener: (_, __) {
          _loadingTimeout?.cancel();
          if (mounted) setState(() => _loading = false);
        },
        buildWhen: (p, c) =>
            p.previewHrRecords != c.previewHrRecords ||
            p.isConnected != c.isConnected,
        builder: (context, state) {
          final records = _sortedByStampDesc(state.previewHrRecords);
          return Column(
            children: [
              if (_loading) const _LoadingBar(),
              if (!state.isConnected)
                const _Banner(
                  icon: Icons.bluetooth_disabled,
                  text: 'No device connected — connect first to load records.',
                ),
              Expanded(
                child: records.isEmpty
                    ? _EmptyState(loading: _loading)
                    : _RecordsList(records: records),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<Map<dynamic, dynamic>> _sortedByStampDesc(
    List<Map<dynamic, dynamic>> src) {
  final list = [...src];
  list.sort((a, b) {
    final sa = (a['stamp'] as num?)?.toInt() ?? 0;
    final sb = (b['stamp'] as num?)?.toInt() ?? 0;
    return sb.compareTo(sa); // latest session first
  });
  return list;
}

// ─── Records list ─────────────────────────────────────────────────────────────

class _RecordsList extends StatelessWidget {
  final List<Map<dynamic, dynamic>> records;
  const _RecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const Icon(Icons.folder_copy_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('${records.length} session record(s)',
                  style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: records.length,
            itemBuilder: (ctx, i) {
              final r = records[i];
              final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
              final record = (r['record'] as num?)?.toInt();
              return _RecordRow(index: i + 1, stamp: stamp, record: record);
            },
          ),
        ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final int index;
  final int stamp;
  final int? record;
  const _RecordRow({
    required this.index,
    required this.stamp,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        RecordDataScreen.route(context, stamp: stamp, record: record),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Center(
                child: Text('$index',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fmtRecordStamp(stamp),
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('session start',
                      style: TextStyle(
                          color: AppColors.subtext.withOpacity(0.9),
                          fontSize: 10.5)),
                ],
              ),
            ),
            if (record != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('rec $record',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ─── Bits ─────────────────────────────────────────────────────────────────────

class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryLight,
      child: Row(
        children: const [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Reading records from device…',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Banner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: AppColors.subtext, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool loading;
  const _EmptyState({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(loading ? Icons.hourglass_top : Icons.inbox_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              loading
                  ? 'Waiting for record headers…'
                  : 'No records yet.\nTap ⟳ to load from device.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Record HEADER stamp — Chileaf band bakes a +5:30 offset into it, so render as
/// UTC (no extra local offset) to show the real wall-clock session start.
String _fmtRecordStamp(int stamp) {
  if (stamp <= 0) return '—';
  final ms = stamp > 9999999999 ? stamp : stamp * 1000;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  final now = DateTime.now().toUtc();
  final isToday =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final dateStr =
      isToday ? 'Today' : '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  return '$dateStr  ${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
}

String _p(int n) => n.toString().padLeft(2, '0');
