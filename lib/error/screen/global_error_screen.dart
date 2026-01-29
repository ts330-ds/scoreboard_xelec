

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
      listenWhen: (prev, curr) =>
      curr.type != ErrorType.none &&
          prev.message != curr.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context).clearSnackBars();

        final snackBar = SnackBar(
          content: Text(state.message),
          backgroundColor:
          state.type == ErrorType.error ? Colors.red : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // ✅ IMPORTANT: clear error after showing
        context.read<GlobalErrorCubit>().clear();

        // Clear the state so the same error can be shown again if needed later
      },
      child: child,
    );
  }
}
