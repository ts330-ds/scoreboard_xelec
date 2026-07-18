import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

/// READ-ONLY detail screen: shows ALL readings inside one HR record (session).
/// Fires `previewHrRecordData(stamp)` — no persist, no server push.
class RecordDataScreen extends StatelessWidget {
  final int stamp;
  final int? record;
  const RecordDataScreen({super.key, required this.stamp, this.record});

  /// Opens the screen preserving the caller's [HeartBleCubit] (the preview
  /// data lands on that cubit's state).
  static Route<void> route(
    BuildContext context, {
    required int stamp,
    int? record,
  }) {
    final cubit = context.read<HeartBleCubit>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: RecordDataScreen(stamp: stamp, record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RecordDataView(stamp: stamp, record: record);
  }
}

class _RecordDataView extends StatefulWidget {
  final int stamp;
  final int? record;
  const _RecordDataView({required this.stamp, this.record});

  @override
  State<_RecordDataView> createState() => _RecordDataViewState();
}

class _RecordDataViewState extends State<_RecordDataView> {
  bool _loading = false;
  Timer? _loadingTimeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestData());
  }

  void _requestData() {
    final cubit = context.read<HeartBleCubit>();
    if (!cubit.state.isConnected) return;
    setState(() => _loading = true);
    _loadingTimeout?.cancel();
    // Bade record ka transfer der le sakta hai — generous timeout.
    _loadingTimeout = Timer(const Duration(seconds: 65), () {
      if (mounted) setState(() => _loading = false);
    });
    cubit.previewHrRecordData(widget.stamp);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Record Data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            Text(
              '${widget.record != null ? 'rec ${widget.record}  ·  ' : ''}${_fmtRecordStamp(widget.stamp)}',
              style: const TextStyle(fontSize: 11, color: AppColors.subtext),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _requestData,
            icon: const Icon(Icons.sync, color: AppColors.primary),
          ),
        ],
      ),
      body: BlocConsumer<HeartBleCubit, HeartBleState>(
        listenWhen: (p, c) =>
            p.previewHrRecordData != c.previewHrRecordData,
        listener: (_, __) {
          _loadingTimeout?.cancel();
          if (mounted) setState(() => _loading = false);
        },
        buildWhen: (p, c) =>
            p.previewHrRecordData != c.previewHrRecordData ||
            p.isConnected != c.isConnected,
        builder: (context, state) {
          final data = _sortedByStampAsc(state.previewHrRecordData);
          return Column(
            children: [
              if (_loading) const _LoadingBar(),
              Expanded(
                child: data.isEmpty
                    ? _EmptyState(loading: _loading)
                    : _DataBody(data: data),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<Map<dynamic, dynamic>> _sortedByStampAsc(List<Map<dynamic, dynamic>> src) {
  final list = [...src];
  list.sort((a, b) {
    final sa = (a['stamp'] as num?)?.toInt() ?? 0;
    final sb = (b['stamp'] as num?)?.toInt() ?? 0;
    return sa.compareTo(sb); // chronological
  });
  return list;
}

// ─── Body: stats + readings list ────────────────────────────────────────────────

class _DataBody extends StatelessWidget {
  final List<Map<dynamic, dynamic>> data;
  const _DataBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final hrs = data
        .map((r) => (r['heartRate'] as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    final avg =
        hrs.isEmpty ? 0 : (hrs.reduce((a, b) => a + b) / hrs.length).round();
    final max = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a > b ? a : b);
    final min = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              _Stat('Readings', '${data.length}', AppColors.primary),
              const SizedBox(width: 8),
              _Stat('Avg', '$avg', AppColors.heartRed),
              const SizedBox(width: 8),
              _Stat('Max', '$max', AppColors.heartRed),
              const SizedBox(width: 8),
              _Stat('Min', '$min', AppColors.heartRed),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final r = data[i];
              final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
              final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
              return _ReadingRow(index: i + 1, stamp: stamp, bpm: hr);
            },
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.75),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final int index;
  final int stamp;
  final int bpm;
  const _ReadingRow(
      {required this.index, required this.stamp, required this.bpm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('$index',
                style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          Text(_fmtDataStamp(stamp),
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
          const Spacer(),
          const Icon(Icons.favorite, color: AppColors.heartRed, size: 13),
          const SizedBox(width: 4),
          Text('$bpm bpm',
              style: const TextStyle(
                  color: AppColors.heartRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
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
          Text('Reading record data from device…',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
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
              loading ? 'Fetching readings…' : 'No readings in this record.',
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

/// Record HEADER stamp — Chileaf band bakes a +5:30 offset into it, so we render
/// it as UTC (no extra local offset) to get the real wall-clock session start.
String _fmtRecordStamp(int stamp) => _fmt(stamp, utc: true);

/// Per-reading DATA stamp — already true UTC epoch, so normal local render.
String _fmtDataStamp(int stamp) => _fmt(stamp, utc: false);

String _fmt(int stamp, {required bool utc}) {
  if (stamp <= 0) return '—';
  final ms = stamp > 9999999999 ? stamp : stamp * 1000;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: utc);
  final now = utc ? DateTime.now().toUtc() : DateTime.now();
  final isToday =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final dateStr =
      isToday ? 'Today' : '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  return '$dateStr  ${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
}

String _p(int n) => n.toString().padLeft(2, '0');
