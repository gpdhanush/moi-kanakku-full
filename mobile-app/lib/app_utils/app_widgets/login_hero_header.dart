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

  /// Dissolves the photo into [fadeColor] so it does not read as a second screen.
  final bool fadeIntoContent;

  /// Scaffold / form color the hero should melt into.
  final Color fadeColor;

  const AuthImageHero({
    super.key,
    required this.height,
    required this.imageAsset,
    this.enableSnow = false,
    this.onBack,
    this.imageAlignment = Alignment.center,
    this.headline,
    this.support,
    this.title,
    this.subtitle,
    this.fadeIntoContent = true,
    this.fadeColor = AppColors.white,
  });

  @override
  State<AuthImageHero> createState() => _AuthImageHeroState();
}

class _AuthImageHeroState extends State<AuthImageHero>
    with SingleTickerProviderStateMixin {
  AnimationController? _snowController;
  List<_Snowflake>? _flakes;
  DateTime? _snowStartedAt;

  @override
  void initState() {
    super.initState();
    if (widget.enableSnow) {
      final random = math.Random(17);
      _flakes = List.generate(36, (_) => _Snowflake.random(random));
      _snowStartedAt = DateTime.now();
      _snowController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
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

    final fadeReserve = widget.fadeIntoContent
        ? (widget.height * 0.30).clamp(48.0, 96.0)
        : AppSpacing.md;
    final photo = Image.asset(
      widget.imageAsset,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: widget.imageAlignment,
      filterQuality: FilterQuality.high,
    );
    final snowLayer = widget.enableSnow &&
            _snowController != null &&
            _flakes != null &&
            _snowStartedAt != null
        ? Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _snowController!,
                    builder: (context, _) {
                      final elapsed = DateTime.now()
                          .difference(_snowStartedAt!)
                          .inMilliseconds /
                          1000.0;
                      return CustomPaint(
                        painter: _SnowPainter(
                          flakes: _flakes!,
                          elapsed: elapsed,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        : null;

    Widget photoLayer = photo;
    if (widget.fadeIntoContent) {
      photoLayer = ClipRect(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [0.0, 0.62, 1.0],
            ).createShader(bounds);
          },
          child: photo,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photoLayer,
          ?snowLayer,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.fadeIntoContent
                    ? [
                        Colors.black.withValues(alpha: 0.16),
                        Colors.black.withValues(alpha: 0.22),
                        Colors.black.withValues(alpha: 0.06),
                        widget.fadeColor.withValues(alpha: 0),
                      ]
                    : [
                        Colors.black.withValues(alpha: 0.16),
                        Colors.black.withValues(alpha: 0.28),
                        primary.withValues(alpha: 0.62),
                      ],
                stops: widget.fadeIntoContent
                    ? const [0.0, 0.40, 0.64, 1.0]
                    : const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          if (widget.fadeIntoContent)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: fadeReserve,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.fadeColor.withValues(alpha: 0),
                        widget.fadeColor.withValues(alpha: 0.55),
                        widget.fadeColor.withValues(alpha: 0.92),
                        widget.fadeColor,
                      ],
                      stops: const [0.0, 0.32, 0.64, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          if (hasOverlay)
            Positioned(
              left: AppSpacing.page,
              right: AppSpacing.page,
              bottom: fadeReserve,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasText(widget.headline))
                    _OutlinedHeroText(
                      text: widget.headline!,
                      outlineColor: primary,
                      style: AppTypography.heroHeadline,
                    ),
                  if (_hasText(widget.support)) ...[
                    const SizedBox(height: 4),
                    _OutlinedHeroText(
                      text: widget.support!,
                      outlineColor: primary,
                      strokeWidth: 1.6,
                      style: AppTypography.heroSupport.copyWith(
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                  if (_hasText(widget.title)) ...[
                    if (_hasText(widget.headline) || _hasText(widget.support))
                      const SizedBox(height: 10),
                    _OutlinedHeroText(
                      text: widget.title!,
                      outlineColor: primary,
                      style: AppTypography.heroHeadline.copyWith(fontSize: 20),
                    ),
                  ],
                  if (_hasText(widget.subtitle)) ...[
                    const SizedBox(height: 4),
                    _OutlinedHeroText(
                      text: widget.subtitle!,
                      outlineColor: primary,
                      strokeWidth: 1.6,
                      style: AppTypography.heroSupport.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
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

/// White fill + theme-colored stroke for readable hero overlay copy.
class _OutlinedHeroText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color outlineColor;
  final double strokeWidth;

  const _OutlinedHeroText({
    required this.text,
    required this.style,
    required this.outlineColor,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = outlineColor,
          ),
        ),
        Text(
          text,
          style: style.copyWith(
            shadows: const [
              Shadow(
                color: Color(0x44000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
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
      imageAsset: AppImages.loginHeroImage,
      enableSnow: true,
      imageAlignment: Alignment.center,
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
      size: 1.1 + random.nextDouble() * 1.5,
      speed: 0.024 + random.nextDouble() * 0.028,
      drift: (random.nextDouble() - 0.5) * 0.14,
      opacity: 0.40 + random.nextDouble() * 0.35,
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> flakes;
  final double elapsed;

  const _SnowPainter({required this.flakes, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final maxFall = size.height * 0.68;

    for (final flake in flakes) {
      final cycle = flake.startY + elapsed * flake.speed;
      final fall = cycle - cycle.floorToDouble();
      final sway = math.sin((elapsed * 0.35 + flake.x) * math.pi * 2) *
          flake.drift;
      final dx = (flake.x + sway).clamp(0.0, 1.0) * size.width;
      final dy = fall * size.height;

      if (dy < -4 || dy > maxFall) continue;

      var alpha = flake.opacity;
      if (fall < 0.08) {
        alpha *= fall / 0.08;
      } else if (fall > 0.52) {
        alpha *= ((0.68 - fall) / 0.16).clamp(0.0, 1.0);
      }
      if (alpha <= 0.02) continue;

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), flake.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed;
  }
}
