import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

class BuzzerButton extends StatelessWidget {
  final BleService bleService;
  final ValueNotifier<bool> _isPressed = ValueNotifier(false);

  BuzzerButton({
    super.key,
    required this.bleService,
  });

  void _onPress() {
    _isPressed.value = true;
    bleService.send("BUZZON");
  }

  void _onRelease() {
    _isPressed.value = false;
    bleService.send("BUZZOFF");
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onPress(),
      onPointerUp: (_) => _onRelease(),
      onPointerCancel: (_) => _onRelease(),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isPressed,
        builder: (context, isPressed, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: isPressed ? 42 : 60,
            height: isPressed ? 42 : 60,
            decoration: BoxDecoration(
              color: isPressed ? Colors.red.shade800 : Colors.red,
              shape: BoxShape.circle,
              boxShadow: isPressed
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.volume_up,
              color: Colors.white,
              size: isPressed ? 32 : 40,
            ),
          );
        },
      ),
    );
  }
}