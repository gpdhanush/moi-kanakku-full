import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:hugeicons/hugeicons.dart';

/// Full-bleed auth hero image (~30% height). Optional soft snowfall for login.
class AuthImageHero extends StatefulWidget {
  final double height;
  final String imageAsset;
  final bool enableSnow;
  final VoidCallback? onBack;
  final Alignment imageAlignment;
  /// Previous marketing headline on the hero (e.g. Every Function Matters).
  final String? headline;
  /// Previous marketing support line under [headline].
  final String? support;
  /// Welcome title shown at the bottom of the hero.
  final String? title;
  /// Welcome subtitle shown under [title].
  final String? subtitle;

  const AuthImageHero({
    super.key,
    required this.height,
    required this.imageAsset,
    this.enableSnow = false,
    this.onBack,
    this.imageAlignment = const Alignment(0, -0.15),
    this.headline,
    this.support,
    this.title,
    this.subtitle,
  });

  @override
  State<AuthImageHero> createState() => _AuthImageHeroState();
}

class _AuthImageHeroState extends State<AuthImageHero>
    with SingleTickerProviderStateMixin {
  AnimationController? _snowController;
  List<_Snowflake>? _flakes;

  @override
  void initState() {
    super.initState();
    if (widget.enableSnow) {
      final random = math.Random(17);
      _flakes = List.generate(72, (_) => _Snowflake.random(random));
      _snowController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 12),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _snowController?.dispose();
    super.dispose();
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final topInset = MediaQuery.paddingOf(context).top;
    final hasOverlay = _hasText(widget.headline) ||
        _hasText(widget.support) ||
        _hasText(widget.title) ||
        _hasText(widget.subtitle);

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.imageAsset,
            fit: BoxFit.cover,
            alignment: widget.imageAlignment,
            filterQuality: FilterQuality.high,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.16),
                  Colors.black.withValues(alpha: 0.28),
                  primary.withValues(alpha: 0.62),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          if (widget.enableSnow &&
              _snowController != null &&
              _flakes != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _snowController!,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SnowPainter(
                        flakes: _flakes!,
                        progress: _snowController!.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (hasOverlay)
            Positioned(
              left: AppSpacing.page,
              right: AppSpacing.page,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasText(widget.headline))
                    Text(
                      widget.headline!,
                      style: AppTypography.heroHeadline.copyWith(
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  if (_hasText(widget.support)) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.support!,
                      style: AppTypography.heroSupport.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_hasText(widget.title)) ...[
                    if (_hasText(widget.headline) || _hasText(widget.support))
                      const SizedBox(height: 10),
                    Text(
                      widget.title!,
                      style: AppTypography.heroHeadline.copyWith(
                        fontSize: 20,
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_hasText(widget.subtitle)) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: AppTypography.heroSupport.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (widget.onBack != null)
            Positioned(
              top: topInset + 8,
              left: 8,
              child: Material(
                color: Colors.white.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 18, color: Colors.white, strokeWidth: 1.8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Login hero with snowfall + overlay copy.
class LoginHeroHeader extends StatelessWidget {
  final double height;
  final String? headline;
  final String? support;
  final String? title;
  final String? subtitle;

  const LoginHeroHeader({
    super.key,
    required this.height,
    this.headline,
    this.support,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AuthImageHero(
      height: height,
      imageAsset: AppImages.weddingHeroImage,
      enableSnow: true,
      headline: headline,
      support: support,
      title: title,
      subtitle: subtitle,
    );
  }
}

class _Snowflake {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double drift;
  final double opacity;

  const _Snowflake({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
  });

  factory _Snowflake.random(math.Random random) {
    return _Snowflake(
      x: random.nextDouble(),
      startY: random.nextDouble(),
      // Soft, small flakes like real snow
      size: 1.1 + random.nextDouble() * 1.6,
      // Slow gentle fall — most flakes drift lightly
      speed: 0.28 + random.nextDouble() * 0.42,
      drift: (random.nextDouble() - 0.5) * 0.18,
      opacity: 0.45 + random.nextDouble() * 0.40,
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> flakes;
  final double progress;

  const _SnowPainter({required this.flakes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final flake in flakes) {
      // Soft continuous fall with light horizontal sway
      final fall = (flake.startY + progress * flake.speed) % 1.12 - 0.06;
      final sway = math.sin((progress * 0.9 + flake.x) * math.pi * 2) *
          flake.drift;
      final dx = (flake.x + sway).clamp(0.0, 1.0) * size.width;
      final dy = fall * size.height;

      if (dy < -4 || dy > size.height + 4) continue;

      paint.color = Colors.white.withValues(alpha: flake.opacity);
      canvas.drawCircle(Offset(dx, dy), flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
