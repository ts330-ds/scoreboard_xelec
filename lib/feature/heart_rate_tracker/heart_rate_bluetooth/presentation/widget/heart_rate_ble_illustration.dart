import 'package:flutter/material.dart';

class HeartBleIllustration extends StatelessWidget {
  final bool isConnected;
  final bool isScanning;
  final int heartRate;

  const HeartBleIllustration({
    super.key,
    this.isConnected = false,
    this.isScanning = false,
    this.heartRate = 0,
  });

  // Ring / accent colour changes with state
  Color get _accentColor {
    if (isConnected) return const Color(0xFF66BB6A);   // green when connected
    if (isScanning) return const Color(0xFF4A90E2);    // blue while scanning
    return const Color(0xFF4A90E2);                    // default blue
  }

  Color get _heartColor {
    if (isConnected && heartRate > 0) return const Color(0xFFEF5350); // red pulse
    if (isConnected) return const Color(0xFF66BB6A);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2235), Color(0xFF0F1626)],
        ),
        border: Border.all(
          color: accent.withOpacity(0.20),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer Ring ───────────────────────────────────────────────
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.07),
                width: 28,
              ),
            ),
          ),

          // ── Middle Ring ──────────────────────────────────────────────
          Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.12),
                width: 18,
              ),
            ),
          ),

          // ── Center Icon ──────────────────────────────────────────────
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
              border: Border.all(
                color: accent.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              isScanning ? Icons.bluetooth_searching : Icons.favorite,
              color: _heartColor,
              size: 32,
            ),
          ),

          // ── Heart Rate Badge (visible only when connected & reading) ─
          if (isConnected && heartRate > 0)
            Positioned(
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2235),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEF5350).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFEF5350),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$heartRate BPM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Scanning label ───────────────────────────────────────────
          if (isScanning && !isConnected)
            Positioned(
              bottom: 28,
              child: Text(
                'Looking for devices…',
                style: TextStyle(
                  color: accent.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // ── Floating Glow Dots ───────────────────────────────────────
          Positioned(
            top: 38,
            right: 48,
            child: _GlowDot(color: accent, size: 8),
          ),
          Positioned(
            bottom: 48,
            left: 44,
            child: _GlowDot(color: accent.withOpacity(0.7), size: 6),
          ),
          Positioned(
            top: 68,
            left: 52,
            child: _GlowDot(color: accent, size: 5),
          ),
        ],
      ),
    );
  }
}

// ── Private Glow Dot ──────────────────────────────────────────────────────────
class _GlowDot extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
