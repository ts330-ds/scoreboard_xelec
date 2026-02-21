import 'package:flutter/material.dart';

class HeartBleDeviceTile extends StatelessWidget {
  final String name;
  final String mac;
  final int rssi;
  final bool isPaired;
  final VoidCallback onTap;

  const HeartBleDeviceTile({
    super.key,
    required this.name,
    required this.mac,
    required this.rssi,
    required this.isPaired,
    required this.onTap,
  });

  String get _signalStrength {
    if (rssi >= -60) return 'Strong';
    if (rssi >= -70) return 'Good';
    return 'Weak';
  }

  Color get _signalColor {
    if (rssi >= -60) return const Color(0xFF66BB6A);
    if (rssi >= -70) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  IconData get _signalIcon {
    if (rssi >= -60) return Icons.signal_cellular_alt;
    if (rssi >= -70) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPaired
                ? const Color(0xFF4A90E2).withOpacity(0.4)
                : const Color(0xFF4A90E2).withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // ── Device Icon ───────────────────────────────────────────
            _buildDeviceIcon(),

            const SizedBox(width: 14),

            // ── Device Info ───────────────────────────────────────────
            Expanded(
              child: _buildDeviceInfo(),
            ),

            // ── Signal Strength ───────────────────────────────────────
            _buildSignalStrength(),
          ],
        ),
      ),
    );
  }

  // ── Device Icon ───────────────────────────────────────────────────────────
  Widget _buildDeviceIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.2),
        ),
      ),
      child: const Icon(
        Icons.watch,
        color: Color(0xFF4A90E2),
        size: 20,
      ),
    );
  }

  // ── Device Info ───────────────────────────────────────────────────────────
  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + Paired Badge
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPaired) ...[
              const SizedBox(width: 8),
              _buildPairedBadge(),
            ],
          ],
        ),

        const SizedBox(height: 4),

        // MAC Address
        Text(
          mac,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ── Paired Badge ──────────────────────────────────────────────────────────
  Widget _buildPairedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Paired',
        style: TextStyle(
          color: Color(0xFF4A90E2),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Signal Strength ───────────────────────────────────────────────────────
  Widget _buildSignalStrength() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _signalIcon,
          color: _signalColor,
          size: 18,
        ),
        const SizedBox(height: 2),
        Text(
          _signalStrength,
          style: TextStyle(
            color: _signalColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
