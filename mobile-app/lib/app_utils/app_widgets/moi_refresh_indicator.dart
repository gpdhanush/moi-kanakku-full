import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Modern pull-to-refresh with MK blue capsule + animated ring.
class MoiRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double offsetToArmed;

  const MoiRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.offsetToArmed = 72,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: offsetToArmed,
      builder: (context, child, controller) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final value = controller.value.clamp(0.0, 1.5);
            final pull = math.min(value, 1.0);
            final show = controller.isDragging ||
                controller.isArmed ||
                controller.isLoading ||
                controller.isComplete;

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Transform.translate(
                  offset: Offset(0, 52 * math.min(value, 1.0)),
                  child: child,
                ),
                if (show)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    child: _MoiRefreshBadge(
                      progress: pull,
                      loading: controller.isLoading || controller.isComplete,
                      armed: controller.isArmed,
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

class _MoiRefreshBadge extends StatelessWidget {
  final double progress;
  final bool loading;
  final bool armed;

  const _MoiRefreshBadge({
    required this.progress,
    required this.loading,
    required this.armed,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scale = reduceMotion ? 1.0 : (0.72 + (0.28 * progress));
    final opacity = reduceMotion ? 1.0 : progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryMid],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(
                  painter: _RefreshRingPainter(
                    progress: loading ? 1 : progress,
                    loading: loading,
                    color: Colors.white.withValues(alpha: 0.95),
                    trackColor: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              if (loading)
                const _SpinningRefreshIcon()
              else
                Transform.rotate(
                  angle: armed ? math.pi : (progress * math.pi * 0.65),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 20,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinningRefreshIcon extends StatefulWidget {
  const _SpinningRefreshIcon();

  @override
  State<_SpinningRefreshIcon> createState() => _SpinningRefreshIconState();
}

class _SpinningRefreshIconState extends State<_SpinningRefreshIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      return const HugeIcon(
        icon: HugeIcons.strokeRoundedRefresh,
        color: Colors.white,
        size: 20,
        strokeWidth: 2,
      );
    }

    return RotationTransition(
      turns: _controller,
      child: const HugeIcon(
        icon: HugeIcons.strokeRoundedRefresh,
        color: Colors.white,
        size: 20,
        strokeWidth: 2,
      ),
    );
  }
}

class _RefreshRingPainter extends CustomPainter {
  final double progress;
  final bool loading;
  final Color color;
  final Color trackColor;

  _RefreshRingPainter({
    required this.progress,
    required this.loading,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final sweep = loading
        ? (math.pi * 1.4)
        : (math.pi * 2 * progress.clamp(0.05, 1.0));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RefreshRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.loading != loading ||
        oldDelegate.color != color;
  }
}
