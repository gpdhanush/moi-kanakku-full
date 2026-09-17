import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Smooth layered wave clip used under auth heroes.
enum WaveCurveStyle {
  soft,
  deep,
  gentle,
}

class WaveBottom extends StatelessWidget {
  final Color color;
  final double height;
  final double opacity;
  final WaveCurveStyle style;
  final double phase;

  const WaveBottom({
    super.key,
    required this.color,
    this.height = 36,
    this.opacity = 1,
    this.style = WaveCurveStyle.soft,
    this.phase = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: WaveBottomPainter(
          color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
          style: style,
          phase: phase,
        ),
      ),
    );
  }
}

class WaveBottomPainter extends CustomPainter {
  final Color color;
  final WaveCurveStyle style;
  final double phase;

  const WaveBottomPainter({
    required this.color,
    required this.style,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildWavePath(size, style: style, phase: phase);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant WaveBottomPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.style != style ||
        (oldDelegate.phase - phase).abs() > 0.0005;
  }
}

Path buildWavePath(
  Size size, {
  required WaveCurveStyle style,
  required double phase,
}) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  // Visible but calm motion (~8–18px depending on wave height).
  final driftX = math.sin(phase * math.pi * 2) * (w * 0.045);
  final liftY = math.cos(phase * math.pi * 2) * (h * 0.22);

  switch (style) {
    case WaveCurveStyle.deep:
      path.moveTo(0, h * 0.40 + liftY * 0.35);
      path.cubicTo(
        w * 0.18 + driftX,
        h * 0.05 - liftY,
        w * 0.34 - driftX,
        h * 0.95 + liftY,
        w * 0.52 + driftX * 0.2,
        h * 0.55 - liftY * 0.4,
      );
      path.cubicTo(
        w * 0.70 + driftX,
        h * 0.16 + liftY,
        w * 0.86 - driftX,
        h * 0.92 - liftY,
        w,
        h * 0.36 + liftY * 0.25,
      );
      break;
    case WaveCurveStyle.gentle:
      path.moveTo(0, h * 0.52 + liftY * 0.3);
      path.quadraticBezierTo(
        w * 0.28 + driftX,
        h * 0.12 - liftY,
        w * 0.52,
        h * 0.48 + liftY * 0.45,
      );
      path.quadraticBezierTo(
        w * 0.78 - driftX,
        h * 0.86 + liftY,
        w,
        h * 0.38 - liftY * 0.2,
      );
      break;
    case WaveCurveStyle.soft:
      path.moveTo(0, h * 0.46 + liftY * 0.25);
      path.cubicTo(
        w * 0.20 + driftX,
        h * 0.08 - liftY,
        w * 0.36 - driftX,
        h * 0.90 + liftY,
        w * 0.54,
        h * 0.50 - liftY * 0.35,
      );
      path.cubicTo(
        w * 0.72 + driftX,
        h * 0.12 + liftY,
        w * 0.88 - driftX,
        h * 0.88 - liftY,
        w,
        h * 0.38 + liftY * 0.2,
      );
      break;
  }

  path
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  return path;
}

/// Soft looping wave motion for auth heroes.
class AnimatedWaveBottom extends StatefulWidget {
  final Color color;
  final double height;
  final double opacity;
  final WaveCurveStyle style;
  final Duration duration;
  final bool reversePhase;

  const AnimatedWaveBottom({
    super.key,
    required this.color,
    this.height = 36,
    this.opacity = 1,
    this.style = WaveCurveStyle.soft,
    this.duration = const Duration(milliseconds: 3200),
    this.reversePhase = false,
  });

  @override
  State<AnimatedWaveBottom> createState() => _AnimatedWaveBottomState();
}

class _AnimatedWaveBottomState extends State<AnimatedWaveBottom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveBottom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = widget.reversePhase
            ? 1 - _controller.value
            : _controller.value;
        return WaveBottom(
          color: widget.color,
          height: widget.height,
          opacity: widget.opacity,
          style: widget.style,
          phase: phase,
        );
      },
    );
  }
}

/// Clips a hero so its bottom edge is a smooth wave (not a hard rectangle).
class WaveHeroClipper extends CustomClipper<Path> {
  final double phase;

  WaveHeroClipper({
    required Listenable reclip,
    required this.phase,
  }) : super(reclip: reclip);

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final wave = h * 0.12;
    final drift = math.sin(phase * math.pi * 2) * (w * 0.03);
    final lift = math.cos(phase * math.pi * 2) * (wave * 0.35);

    return Path()
      ..lineTo(0, h - wave + lift * 0.25)
      ..cubicTo(
        w * 0.22 + drift,
        h - wave * 2.1 - lift,
        w * 0.38 - drift,
        h + wave * 0.15 + lift * 0.2,
        w * 0.52,
        h - wave * 0.85 + lift * 0.15,
      )
      ..cubicTo(
        w * 0.68 + drift,
        h - wave * 1.85 + lift,
        w * 0.84 - drift,
        h + wave * 0.05 - lift * 0.1,
        w,
        h - wave * 0.7 - lift * 0.2,
      )
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant WaveHeroClipper oldClipper) {
    return (oldClipper.phase - phase).abs() > 0.0005;
  }
}
