import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: widget.onTap,
      child: Tooltip(
        message: 'Sync history from device',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.50)),
          ),
          child: RotationTransition(
            turns: _spin,
            child: const Icon(Icons.sync,
                color: Colors.white,
                size: 18),
          ),
        ),
      ),
    );
  }
}
