import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

/// Modern Tailwind-style pull-to-refresh: soft pill + theme spinner.
class MoiRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double offsetToArmed;

  const MoiRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.offsetToArmed = 68,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: offsetToArmed,
      builder: (context, child, controller) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final value = controller.value.clamp(0.0, 1.4);
            final pull = math.min(value, 1.0);
            final loading = controller.isLoading || controller.isComplete;
            final show = controller.isDragging ||
                controller.isArmed ||
                loading;

            final displace = 48.0 * Curves.easeOut.transform(pull);

            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: Offset(0, displace),
                  child: child,
                ),
                if (show)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 6,
                    child: _RefreshPill(
                      progress: pull,
                      loading: loading,
                      armed: controller.isArmed,
                      primary: primary,
                    ),
                  ),
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}

class _RefreshPill extends StatelessWidget {
  final double progress;
  final bool loading;
  final bool armed;
  final Color primary;

  const _RefreshPill({
    required this.progress,
    required this.loading,
    required this.armed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final opacity = reduceMotion ? 1.0 : progress.clamp(0.0, 1.0);
    final scale = reduceMotion ? 1.0 : (0.86 + (0.14 * progress));
    final y = reduceMotion ? 0.0 : (1 - progress) * -10;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, y),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xffE4E4E7), // zinc-200
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xff09090B).withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: loading
                ? _SpinningArc(color: primary)
                : SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(
                      painter: _ProgressArcPainter(
                        progress: armed ? 1 : progress,
                        color: primary,
                        trackColor: primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SpinningArc extends StatefulWidget {
  final Color color;

  const _SpinningArc({required this.color});

  @override
  State<_SpinningArc> createState() => _SpinningArcState();
}

class _SpinningArcState extends State<_SpinningArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: widget.color,
        ),
      );
    }

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(
          painter: _ProgressArcPainter(
            progress: 0.72,
            color: widget.color,
            trackColor: widget.color.withValues(alpha: 0.12),
            sweepOnly: true,
          ),
        ),
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final bool sweepOnly;

  _ProgressArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.sweepOnly = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 1.5;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    if (!sweepOnly) {
      canvas.drawCircle(center, radius, track);
    } else {
      canvas.drawCircle(center, radius, track);
    }

    final sweep = math.pi * 2 * progress.clamp(0.08, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.sweepOnly != sweepOnly;
  }
}
