import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';

class SyncButton extends StatefulWidget {
  final bool isSyncing;
  final VoidCallback? onTap;
  const SyncButton({super.key, required this.isSyncing, this.onTap});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.isSyncing) _spin.repeat();
  }

  @override
  void didUpdateWidget(SyncButton old) {
    super.didUpdateWidget(old);
    if (widget.isSyncing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isSyncing && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        context.select<HeartBleCubit, bool>((c) => c.state.isConnected);
    return GestureDetector(
      onTap: connected ? widget.onTap : null,
      child: Tooltip(
        message:
            connected ? 'Sync history from device' : 'Connect a device first',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: connected ? 0.20 : 0.10),
            border: Border.all(
                color:
                    Colors.white.withValues(alpha: connected ? 0.50 : 0.20)),
          ),
          child: RotationTransition(
            turns: _spin,
            child: Icon(Icons.sync,
                color: connected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.40),
                size: 18),
          ),
        ),
      ),
    );
  }
}
