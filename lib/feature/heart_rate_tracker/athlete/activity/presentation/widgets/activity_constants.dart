import 'package:flutter/material.dart';

class ActivityType {
  final String name;
  final IconData icon;
  final Color color;
  const ActivityType(this.name, this.icon, this.color);
}

const List<ActivityType> activityTypes = [
  ActivityType('Running',    Icons.directions_run,    Color(0xFFEF5350)),
  ActivityType('Cricket',    Icons.sports_cricket,    Color(0xFF43A047)),
  ActivityType('Swimming',   Icons.pool,              Color(0xFF1E88E5)),
  ActivityType('Cycling',    Icons.directions_bike,   Color(0xFF8E24AA)),
  ActivityType('Basketball', Icons.sports_basketball, Color(0xFFFF7043)),
  ActivityType('Football',   Icons.sports_soccer,     Color(0xFF00897B)),
  ActivityType('Badminton',  Icons.sports_tennis,     Color(0xFF00ACC1)),
  ActivityType('Boxing',     Icons.sports_mma,        Color(0xFFE91E63)),
  ActivityType('Yoga',       Icons.self_improvement,  Color(0xFF7CB342)),
  ActivityType('Gym',        Icons.fitness_center,    Color(0xFFFF5722)),
  ActivityType('Walking',    Icons.directions_walk,   Color(0xFF3949AB)),
  ActivityType('Other',      Icons.sports,            Color(0xFF6D4C41)),
];

const List<int> durationOptions = [15, 20, 30, 40, 45, 60, 90, 120];

ActivityType typeFor(String name) => activityTypes.firstWhere(
      (a) => a.name == name,
      orElse: () => activityTypes.last,
    );
