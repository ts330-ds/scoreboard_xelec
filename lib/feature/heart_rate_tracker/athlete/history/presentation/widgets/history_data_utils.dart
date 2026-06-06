import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class DailyStats {
  final DateTime date;
  final int avg;
  final int max;
  final int min;
  final int count;
  const DailyStats({
    required this.date,
    required this.avg,
    required this.max,
    required this.min,
    required this.count,
  });
}

class TimeSlotStats {
  final String label;
  final String timeRange;
  final IconData icon;
  final Color color;
  final int avgHr;
  final int count;
  const TimeSlotStats({
    required this.label,
    required this.timeRange,
    required this.icon,
    required this.color,
    required this.avgHr,
    required this.count,
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

DateTime stampToDateTime(int stamp) {
  final ms = stamp > 9999999999 ? stamp : stamp * 1000;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

String formatHour(int hour) {
  if (hour == 0) return '12 AM';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return '12 PM';
  return '${hour - 12} PM';
}

String pad2(int n) => n.toString().padLeft(2, '0');

List<Map<dynamic, dynamic>> dedupeHrData(List<Map<dynamic, dynamic>> data) {
  if (data.isEmpty) return data;
  final seenStamps = <int>{};
  return data.where((r) {
    final s = (r['stamp'] as num?)?.toInt() ?? 0;
    if (s <= 0) return true;
    return seenStamps.add(s);
  }).toList();
}

List<Map<dynamic, dynamic>> filterByDateRange(
  List<Map<dynamic, dynamic>> data,
  DateTime? from,
  DateTime? to,
) {
  if (from == null && to == null) return data;
  return data.where((r) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    if (stamp <= 0) return false;
    final dt = stampToDateTime(stamp);
    if (from != null && dt.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null &&
        dt.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }).toList();
}

Map<String, List<Map<dynamic, dynamic>>> groupByDate(
    List<Map<dynamic, dynamic>> data) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final fmt = DateFormat('dd MMM yyyy');

  final grouped = <String, List<Map<dynamic, dynamic>>>{};
  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    if (stamp <= 0) continue;
    final dt = stampToDateTime(stamp);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    String label;
    if (dtDay == today) {
      label = 'Today';
    } else if (dtDay == yesterday) {
      label = 'Yesterday';
    } else {
      label = fmt.format(dt);
    }
    grouped.putIfAbsent(label, () => []).add(r);
  }
  return grouped;
}

List<DailyStats> dailyAggregates(List<Map<dynamic, dynamic>> data) {
  final byDay = <String, List<int>>{};
  final dayDates = <String, DateTime>{};

  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    final dt = stampToDateTime(stamp);
    final key = '${dt.year}-${dt.month}-${dt.day}';
    byDay.putIfAbsent(key, () => []).add(hr);
    dayDates.putIfAbsent(key, () => DateTime(dt.year, dt.month, dt.day));
  }

  final result = byDay.entries.map((e) {
    final hrs = e.value;
    final avg = (hrs.reduce((a, b) => a + b) / hrs.length).round();
    final max = hrs.reduce((a, b) => a > b ? a : b);
    final min = hrs.reduce((a, b) => a < b ? a : b);
    return DailyStats(
        date: dayDates[e.key]!, avg: avg, max: max, min: min, count: hrs.length);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return result;
}

List<TimeSlotStats> timeOfDayAggregates(List<Map<dynamic, dynamic>> data) {
  final buckets = <String, List<int>>{
    'Morning': [],
    'Afternoon': [],
    'Evening': [],
    'Night': [],
  };

  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    final hour = stampToDateTime(stamp).hour;
    if (hour >= 5 && hour <= 11) {
      buckets['Morning']!.add(hr);
    } else if (hour >= 12 && hour <= 16) {
      buckets['Afternoon']!.add(hr);
    } else if (hour >= 17 && hour <= 20) {
      buckets['Evening']!.add(hr);
    } else {
      buckets['Night']!.add(hr);
    }
  }

  int avg(List<int> list) =>
      list.isEmpty ? 0 : (list.reduce((a, b) => a + b) / list.length).round();

  return [
    TimeSlotStats(
        label: 'Morning',
        timeRange: '5 AM – 12 PM',
        icon: Icons.wb_sunny_outlined,
        color: AppColors.warning,
        avgHr: avg(buckets['Morning']!),
        count: buckets['Morning']!.length),
    TimeSlotStats(
        label: 'Afternoon',
        timeRange: '12 PM – 5 PM',
        icon: Icons.light_mode_outlined,
        color: AppColors.heartRed,
        avgHr: avg(buckets['Afternoon']!),
        count: buckets['Afternoon']!.length),
    TimeSlotStats(
        label: 'Evening',
        timeRange: '5 PM – 9 PM',
        icon: Icons.nights_stay_outlined,
        color: AppColors.vitalBP,
        avgHr: avg(buckets['Evening']!),
        count: buckets['Evening']!.length),
    TimeSlotStats(
        label: 'Night',
        timeRange: '9 PM – 5 AM',
        icon: Icons.dark_mode_outlined,
        color: AppColors.vitalStress,
        avgHr: avg(buckets['Night']!),
        count: buckets['Night']!.length),
  ];
}

({int peakHour, int peakAvg, List<int> hourlyAvg}) peakHourDetection(
    List<Map<dynamic, dynamic>> data) {
  final buckets = List.generate(24, (_) => <int>[]);
  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    buckets[stampToDateTime(stamp).hour].add(hr);
  }
  final hourlyAvg = buckets
      .map((list) =>
          list.isEmpty ? 0 : (list.reduce((a, b) => a + b) / list.length).round())
      .toList();
  int peakHour = 0;
  int peakAvg = 0;
  for (int h = 0; h < 24; h++) {
    if (hourlyAvg[h] > peakAvg) {
      peakAvg = hourlyAvg[h];
      peakHour = h;
    }
  }
  return (peakHour: peakHour, peakAvg: peakAvg, hourlyAvg: hourlyAvg);
}

// ─── Sleep helpers ───────────────────────────────────────────────────────────

String sleepStageLabel(int code) {
  switch (code) {
    case 1:
      return 'Deep';
    case 2:
      return 'Light';
    case 3:
      return 'REM';
    case 4:
      return 'Awake';
    default:
      return 'Unknown';
  }
}

Color sleepStageColor(int code) {
  switch (code) {
    case 1:
      return AppColors.primary;
    case 2:
      return AppColors.vitalBP;
    case 3:
      return AppColors.vitalStress;
    case 4:
      return AppColors.warning;
    default:
      return AppColors.subtext;
  }
}

class SleepSession {
  final DateTime start;
  final DateTime end;
  final int totalMin;
  final Map<int, int> stageMinutes;
  final List<int> actions;
  const SleepSession({
    required this.start,
    required this.end,
    required this.totalMin,
    required this.stageMinutes,
    required this.actions,
  });
}

SleepSession? parseSleepSession(Map<dynamic, dynamic> raw) {
  final utc = (raw['utc'] as num?)?.toInt() ?? 0;
  if (utc <= 0) return null;
  final rawActions = raw['actions'];
  final actions = rawActions is List
      ? rawActions.whereType<num>().map((e) => e.toInt()).toList()
      : <int>[];
  if (actions.isEmpty) return null;
  final start = stampToDateTime(utc);
  final end = start.add(Duration(minutes: actions.length));
  final stageMinutes = <int, int>{};
  for (final a in actions) {
    stageMinutes[a] = (stageMinutes[a] ?? 0) + 1;
  }
  return SleepSession(
    start: start,
    end: end,
    totalMin: actions.length,
    stageMinutes: stageMinutes,
    actions: actions,
  );
}

String fmtDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Friendly last-sync label with both relative + absolute time.
/// Example outputs:
///   "Just now • 14:32"
///   "12 min ago • 14:20"
///   "Today 09:15"
///   "Yesterday 22:40"
///   "23 May 2026, 14:32"
String fmtLastSync(int lastSyncMs) {
  if (lastSyncMs <= 0) return 'Never synced';
  final dt = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dtDay = DateTime(dt.year, dt.month, dt.day);
  final diff = now.difference(dt);
  final timeFmt = DateFormat('HH:mm');

  if (diff.inSeconds < 60) return 'Just now • ${timeFmt.format(dt)}';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago • ${timeFmt.format(dt)}';
  }
  if (dtDay == today) return 'Today ${timeFmt.format(dt)}';
  if (dtDay == today.subtract(const Duration(days: 1))) {
    return 'Yesterday ${timeFmt.format(dt)}';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago • ${DateFormat('dd MMM HH:mm').format(dt)}';
  }
  return DateFormat('dd MMM yyyy, HH:mm').format(dt);
}

/// Friendly data-range label with both dates AND clock time, so the user
/// sees exactly the oldest and newest moment of stored data.
/// Example:
///   "Same day"         → "23 May, 08:15 → 19:42"
///   "Cross-day"        → "24 Feb 00:14 → 22 May 23:58"
String fmtDataRange(int oldestStamp, int newestStamp) {
  if (oldestStamp <= 0 || newestStamp <= 0) return 'No data';
  final from = stampToDateTime(oldestStamp);
  final to = stampToDateTime(newestStamp);
  final dateFmt = DateFormat('dd MMM');
  final timeFmt = DateFormat('HH:mm');
  final sameDay =
      from.year == to.year && from.month == to.month && from.day == to.day;
  if (sameDay) {
    return '${dateFmt.format(from)}, ${timeFmt.format(from)} → ${timeFmt.format(to)}';
  }
  return '${dateFmt.format(from)} ${timeFmt.format(from)} → ${dateFmt.format(to)} ${timeFmt.format(to)}';
}
