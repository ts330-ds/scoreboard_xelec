import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

import '../cubit/error_state.dart';

class GlobalErrorToastListener extends StatelessWidget {
  final Widget child;
  const GlobalErrorToastListener({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GlobalErrorCubit, GlobalErrorState>(
      listenWhen: (prev, curr) => curr.type != ErrorType.none,
      listener: (context, state) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(state));
        context.read<GlobalErrorCubit>().clear();
      },
      child: child,
    );
  }

  SnackBar _buildSnackBar(GlobalErrorState state) {
    final config = _configFor(state.type);
    return SnackBar(
      content: Row(
        children: [
          Icon(config.icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      backgroundColor: config.color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: Duration(milliseconds: config.durationMs),
    );
  }

  _ToastConfig _configFor(ErrorType type) => switch (type) {
        ErrorType.error => _ToastConfig(
            color: const Color(0xFFDC2626),
            icon: Icons.error_outline,
            durationMs: 3000,
          ),
        ErrorType.warning => _ToastConfig(
            color: const Color(0xFFD97706),
            icon: Icons.warning_amber_rounded,
            durationMs: 2500,
          ),
        ErrorType.success => _ToastConfig(
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline,
            durationMs: 2000,
          ),
        ErrorType.info => _ToastConfig(
            color: const Color(0xFF1565C0),
            icon: Icons.info_outline,
            durationMs: 2000,
          ),
        ErrorType.none => _ToastConfig(
            color: Colors.transparent,
            icon: Icons.info_outline,
            durationMs: 0,
          ),
      };
}

class _ToastConfig {
  final Color color;
  final IconData icon;
  final int durationMs;
  const _ToastConfig({
    required this.color,
    required this.icon,
    required this.durationMs,
  });
}
