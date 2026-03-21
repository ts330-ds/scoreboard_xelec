import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'data/repositories/session_repository.dart';
import 'features/dashboard/cubit/dashboard_cubit.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/wizard/cubit/wizard_cubit.dart';
import 'features/wizard/screens/step1_setup_screen.dart';
import 'features/wizard/screens/step2_athletes_screen.dart';
import 'features/wizard/screens/step3_gates_screen.dart';
import 'features/wizard/screens/step4_config_screen.dart';
import 'features/wizard/screens/step5_run_screen.dart';
import 'features/wizard/screens/step6_results_screen.dart';
import 'features/run_test/cubit/run_test_cubit.dart';
import 'features/sessions/screens/session_detail_screen.dart';
import 'features/ble/cubit/ble_cubit.dart';

final sessionRepository = SessionRepository();

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  debugLogDiagnostics: true,
  routes: [
    // ── DASHBOARD ────────────────────────────────────────
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => BlocProvider(
        create: (_) => DashboardCubit(sessionRepository)..loadDashboard(),
        child: const DashboardScreen(),
      ),
    ),

    // ── TEST WIZARD ──────────────────────────────────────
    // ShellRoute wraps all 6 steps with shared WizardCubit + BleCubit
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => WizardCubit()),
          BlocProvider(create: (_) => BleCubit()..startScan()),
        ],
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/wizard/setup',
          name: 'wizard-setup',
          builder: (_, __) => const Step1SetupScreen(),
        ),
        GoRoute(
          path: '/wizard/athletes',
          name: 'wizard-athletes',
          builder: (_, __) => const Step2AthletesScreen(),
        ),
        GoRoute(
          path: '/wizard/gates',
          name: 'wizard-gates',
          builder: (_, __) => const Step3GatesScreen(),
        ),
        GoRoute(
          path: '/wizard/config',
          name: 'wizard-config',
          builder: (_, __) => const Step4ConfigScreen(),
        ),
        GoRoute(
          path: '/wizard/run',
          name: 'wizard-run',
          builder: (context, state) => BlocProvider(
            create: (_) => RunTestCubit(),
            child: const Step5RunScreen(),
          ),
        ),
        GoRoute(
          path: '/wizard/results',
          name: 'wizard-results',
          builder: (_, __) => Step6ResultsScreen(repository: sessionRepository),
        ),
      ],
    ),

    // ── SESSION DETAIL ───────────────────────────────────
    GoRoute(
      path: '/sessions/:id',
      name: 'session-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SessionDetailScreen(sessionId: id, repository: sessionRepository);
      },
    ),
  ],
);
