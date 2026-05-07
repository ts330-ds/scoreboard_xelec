import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class AthleteSleepDetailScreen extends StatefulWidget {
  const AthleteSleepDetailScreen({super.key});

  @override
  State<AthleteSleepDetailScreen> createState() =>
      _AthleteSleepDetailScreenState();
}

class _AthleteSleepDetailScreenState extends State<AthleteSleepDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfNeeded());
  }

  void _syncIfNeeded() {
    final cubit = context.read<HeartBleCubit>();
    if (cubit.state.isConnected && cubit.state.historySleep.isEmpty) {
      cubit.syncAllHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Sleep History',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<HeartBleCubit, HeartBleState>(
            buildWhen: (p, c) =>
                p.isConnected != c.isConnected ||
                p.status != c.status,
            builder: (context, state) {
              final syncing = state.status.contains('yncing');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: state.isConnected
                      ? 'Sync sleep data'
                      : 'Connect device to sync',
                  onPressed: state.isConnected && !syncing
                      ? () => context.read<HeartBleCubit>().syncAllHistory()
                      : null,
                  icon: syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          Icons.sync,
                          color: state.isConnected
                              ? Colors.white
                              : Colors.white38,
                        ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HeartBleCubit, HeartBleState>(
        buildWhen: (p, c) => p.historySleep != c.historySleep,
        builder: (context, state) {
          if (state.historySleep.isEmpty) {
            return _EmptyState();
          }

          // Sort: most recent first by utc
          final sorted = [...state.historySleep]
            ..sort((a, b) {
              final at = (a['utc'] as num?)?.toInt() ?? 0;
              final bt = (b['utc'] as num?)?.toInt() ?? 0;
              return bt.compareTo(at);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (_, i) => _SleepRecordCard(
              record: sorted[i],
              isLatest: i == 0,
            ),
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bedtime_outlined,
                color: Color(0xFF5C6BC0), size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No Sleep Data',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Connect your device and sync\nfrom the History tab',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.subtext, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Single Sleep Record Card ──────────────────────────────────────────────────
class _SleepRecordCard extends StatelessWidget {
  final Map<dynamic, dynamic> record;
  final bool isLatest;

  const _SleepRecordCard({required this.record, required this.isLatest});

  static const _deepColor  = Color(0xFF5C6BC0);
  static const _lightColor = Color(0xFF80CBC4);
  static const _awakeColor = Color(0xFFEF9A9A);

  ({int total, int deep, int light, int awake}) _parse() {
    final raw = record['actions'];
    final actions = raw is List
        ? raw.map((e) => (e as num?)?.toInt() ?? 0).toList()
        : <int>[];
    final deep  = actions.where((a) => a >= 2).length;
    final light = actions.where((a) => a == 1).length;
    final awake = actions.where((a) => a == 0).length;
    return (total: actions.length, deep: deep, light: light, awake: awake);
  }

  String _fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _date(int utcSecs) {
    if (utcSecs == 0) return 'Unknown date';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      utcSecs * 1000,
      isUtc: false,
    );
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dow = days[dt.weekday - 1];
    return '$dow, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  (String, Color) _quality(int deep, int sleep) {
    if (sleep == 0) return ('--', AppColors.subtext);
    final p = deep / sleep;
    if (p >= 0.25) return ('Excellent', AppColors.success);
    if (p >= 0.15) return ('Good', const Color(0xFF26A69A));
    if (p >= 0.08) return ('Fair', AppColors.warning);
    return ('Light', AppColors.error);
  }

  @override
  Widget build(BuildContext context) {
    final d    = _parse();
    final utc  = (record['utc'] as num?)?.toInt() ?? 0;
    final sl   = d.deep + d.light;
    final (qLabel, qColor) = _quality(d.deep, sl);
    final deepFrac  = d.total > 0 ? d.deep  / d.total : 0.0;
    final lightFrac = d.total > 0 ? d.light / d.total : 0.0;
    final awakeFrac = d.total > 0 ? d.awake / d.total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLatest ? _deepColor.withAlpha(80) : AppColors.border,
          width: isLatest ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row + badge
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _deepColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bedtime_outlined, color: _deepColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLatest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: _deepColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Last Night',
                          style: TextStyle(
                              color: _deepColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  Text(_date(utc),
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: qColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(qLabel,
                  style: TextStyle(
                      color: qColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),

          const SizedBox(height: 14),

          // Total duration
          Text(_fmt(d.total),
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          const SizedBox(height: 4),
          Text('Total session  •  Sleep: ${_fmt(sl)}',
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),

          const SizedBox(height: 16),

          // Stage bar
          if (d.total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                Flexible(
                    flex: (deepFrac * 100).round(),
                    child: Container(height: 10, color: _deepColor)),
                Flexible(
                    flex: (lightFrac * 100).round(),
                    child: Container(height: 10, color: _lightColor)),
                Flexible(
                    flex: (awakeFrac * 100).round().clamp(0, 100),
                    child: Container(height: 10, color: _awakeColor.withAlpha(80))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Stage legend
          Row(children: [
            _legend(_deepColor,  'Deep',  _fmt(d.deep)),
            const SizedBox(width: 20),
            _legend(_lightColor, 'Light', _fmt(d.light)),
            const SizedBox(width: 20),
            _legend(_awakeColor, 'Awake', _fmt(d.awake)),
          ]),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.subtext, fontSize: 10)),
          Text(value,  style: const TextStyle(
              color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    ],
  );
}
