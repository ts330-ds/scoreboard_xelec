import 'package:flutter/material.dart';

class HeartBleStatusChip extends StatelessWidget {
  final bool isConnected;
  final String status;        // live text from cubit (e.g. "Scanning...", "Connected")
  final String? deviceName;

  const HeartBleStatusChip({
    super.key,
    required this.isConnected,
    required this.status,
    this.deviceName,
  });

  Color get _dotColor {
    if (isConnected) return const Color(0xFF66BB6A);
    if (status.toLowerCase().contains('scan') ||
        status.toLowerCase().contains('connect')) {
      return const Color(0xFFFFA726); // amber while in-progress
    }
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    final label = isConnected
        ? 'Connected${deviceName != null ? ' · $deviceName' : ''}'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF66BB6A).withOpacity(0.3)
              : const Color(0xFF4A90E2).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Animated Status Dot ──────────────────────────────────────
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
              boxShadow: [
                BoxShadow(
                  color: _dotColor.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Status Text ──────────────────────────────────────────────
          Text(
            label,
            style: TextStyle(
              color: isConnected ? const Color(0xFF66BB6A) : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          // ── Connected Icon ───────────────────────────────────────────
          if (isConnected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.bluetooth_connected,
              color: Color(0xFF66BB6A),
              size: 14,
            ),
          ],
        ],
      ),
    );
  }
}
