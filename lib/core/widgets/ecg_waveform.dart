import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ICU-style heart-rate waveform.
///
/// Sirf live BPM se driven hota hai — koi raw ECG/PPG signal ki zaroorat nahi.
/// Waveform locally animate hoti hai aur har naya [bpm] beats ki SPEED set karta
/// hai (beat interval = 60 / bpm). Ye ek synthesized trace hai (dikhne mein ICU
/// jaisi) — actual ECG morphology nahi, kyunki device sirf heart rate deta hai.
///
/// Purely presentational widget. Iska app ke kisi socket/cubit/business logic se
/// koi lena-dena nahi — sirf upar se ek [bpm] int leta hai.
class EcgWaveform extends StatefulWidget {
  /// Live heart rate (bpm). 0/negative ya [active]=false hone par flatline.
  final int bpm;

  /// Jab false ho (athlete stopped / offline / no reading) to flatline dikhe.
  final bool active;

  final double height;
  final Color lineColor;
  final Color backgroundColor;

  /// null ho to [lineColor] se halka grid auto-banta hai.
  final Color? gridColor;
  final bool showGrid;
  final double lineWidth;

  /// Trace kitni tezi se scroll kare (pixels/second). Bada = tez scroll.
  final double pxPerSecond;
  final BorderRadius? borderRadius;

  const EcgWaveform({
    super.key,
    required this.bpm,
    this.active = true,
    this.height = 120,
    this.lineColor = const Color(0xFF3DFF95),
    this.backgroundColor = const Color(0xFF05140D),
    this.gridColor,
    this.showGrid = true,
    this.lineWidth = 2,
    this.pxPerSecond = 160,
    this.borderRadius,
  });

  @override
  State<EcgWaveform> createState() => _EcgWaveformState();
}

class _EcgWaveformState extends State<EcgWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final _EcgPainter _painter;

  Color get _resolvedGrid =>
      widget.gridColor ?? widget.lineColor.withOpacity(0.10);

  @override
  void initState() {
    super.initState();
    // Repeat sirf har frame pe tick dene ke liye — value use nahi hoti.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _painter = _EcgPainter(
      repaint: _ctrl,
      bpm: widget.bpm.toDouble(),
      active: widget.active,
      lineColor: widget.lineColor,
      backgroundColor: widget.backgroundColor,
      gridColor: _resolvedGrid,
      showGrid: widget.showGrid,
      lineWidth: widget.lineWidth,
      pxPerSecond: widget.pxPerSecond,
    );
  }

  @override
  void didUpdateWidget(covariant EcgWaveform old) {
    super.didUpdateWidget(old);
    // Same painter instance ko reuse karte hain (buffer/phase preserve rahe);
    // bas fields update kar dete hain — agla frame naye values use karega.
    _painter
      ..bpm = widget.bpm.toDouble()
      ..active = widget.active
      ..lineColor = widget.lineColor
      ..backgroundColor = widget.backgroundColor
      ..gridColor = _resolvedGrid
      ..showGrid = widget.showGrid
      ..lineWidth = widget.lineWidth
      ..pxPerSecond = widget.pxPerSecond;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(painter: _painter),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter({
    required Listenable repaint,
    required this.bpm,
    required this.active,
    required this.lineColor,
    required this.backgroundColor,
    required this.gridColor,
    required this.showGrid,
    required this.lineWidth,
    required this.pxPerSecond,
  }) : super(repaint: repaint);

  double bpm;
  bool active;
  Color lineColor;
  Color backgroundColor;
  Color gridColor;
  bool showGrid;
  double lineWidth;
  double pxPerSecond;

  // Persistent rolling buffer (size == width in px). Har frame right edge pe
  // naya sample add hota hai, left se ek nikalta hai → scroll effect.
  final List<double> _buf = [];
  double _phase = 0;
  int? _lastMicros;
  double _carry = 0;

  // Ek beat (P-QRS-T) ka synthetic shape, phase p ∈ [0,1).
  static double _beat(double p) {
    double g(double c, double w, double a) =>
        a * math.exp(-((p - c) * (p - c)) / (2 * w * w));
    double v = 0;
    v += g(0.18, 0.018, 0.12); // P wave
    v += g(0.255, 0.008, -0.16); // Q
    v += g(0.28, 0.0085, 1.0); // R (spike)
    v += g(0.31, 0.009, -0.30); // S
    v += g(0.52, 0.032, 0.22); // T wave
    return v;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.floor();
    if (w <= 0 || size.height <= 0) return;

    // Buffer ko width ke barabar rakho (resize pe tail preserve).
    if (_buf.length != w) {
      if (_buf.isEmpty) {
        _buf.addAll(List.filled(w, 0.0));
      } else if (_buf.length < w) {
        _buf.insertAll(0, List.filled(w - _buf.length, 0.0));
      } else {
        _buf.removeRange(0, _buf.length - w);
      }
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    double dt = _lastMicros == null ? 0 : (now - _lastMicros!) / 1e6;
    _lastMicros = now;
    if (dt > 0.05) dt = 0.05; // app background se aane pe bada jump na ho
    if (dt < 0) dt = 0;

    final advance = pxPerSecond * dt + _carry;
    int steps = advance.floor();
    _carry = advance - steps;
    if (steps > w) steps = w;

    final beatsPerSec = (bpm <= 0 ? 0 : bpm) / 60.0;
    final phasePerPx = pxPerSecond <= 0 ? 0 : beatsPerSec / pxPerSecond;
    final live = active && bpm > 0;
    for (int i = 0; i < steps; i++) {
      if (live) {
        _phase += phasePerPx;
        if (_phase >= 1) _phase -= 1;
        _buf.add(_beat(_phase));
      } else {
        _buf.add(0.0);
      }
      _buf.removeAt(0);
    }

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    if (showGrid) {
      final gp = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 22) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
      }
      for (double y = 0; y < size.height; y += 22) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
      }
    }

    final mid = size.height * 0.62;
    final amp = size.height * 0.42;
    final path = Path();
    for (int x = 0; x < _buf.length; x++) {
      final y = mid - _buf[x] * amp;
      if (x == 0) {
        path.moveTo(x.toDouble(), y);
      } else {
        path.lineTo(x.toDouble(), y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) => false;
}
