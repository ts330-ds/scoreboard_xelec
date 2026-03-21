import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/models/athlete_model.dart';
import 'data/models/trial_result_model.dart';
import 'data/models/session_model.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ── Hive Init ──────────────────────────────────────────
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(AthleteModelAdapter());
  Hive.registerAdapter(TrialResultModelAdapter());
  Hive.registerAdapter(SessionModelAdapter());

  // Open boxes
  await Hive.openBox<SessionModel>('sessions');
  await Hive.openBox<AthleteModel>('athletes'); // global roster

  runApp(const ApexApp());
}

class ApexApp extends StatelessWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'APEX Timing Gates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
