import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

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

  Color get _accentColor {
    if (isConnected) return AppColors.success;
    if (isScanning) return AppColors.primary;
    return AppColors.primary;
  }

  Color get _heartColor {
    if (isConnected && heartRate > 0) return AppColors.heartRed;
    if (isConnected) return AppColors.success;
    return AppColors.heartRed;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.surface,
        border: Border.all(
          color: accent.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer Ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.08),
                width: 28,
              ),
            ),
          ),

          // ── Middle Ring
          Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(0.14),
                width: 18,
              ),
            ),
          ),

          // ── Center Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.10),
              border: Border.all(
                color: accent.withOpacity(0.30),
                width: 1.5,
              ),
            ),
            child: Icon(
              isScanning ? Icons.bluetooth_searching : Icons.favorite,
              color: _heartColor,
              size: 32,
            ),
          ),

          // ── Heart Rate Badge
          if (isConnected && heartRate > 0)
            Positioned(
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.heartRed.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.heartRed.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppColors.heartRed,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$heartRate BPM',
                      style: const TextStyle(
                        color: AppColors.heartRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Scanning label
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

          // ── Floating Glow Dots
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
