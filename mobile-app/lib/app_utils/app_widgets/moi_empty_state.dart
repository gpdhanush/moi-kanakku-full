import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Reusable empty / no-results state used across multiple screens.
class MoiEmptyState extends StatefulWidget {
  final String title;
  final String? subtitle;
  final dynamic icon;
  final String? imagePath;
  final Color? accentColor;
  final double imageSize;

  const MoiEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imagePath = 'assets/images/empty-state/function-empty.png',
    this.accentColor,
    this.imageSize = 110,
  });

  @override
  State<MoiEmptyState> createState() => _MoiEmptyStateState();
}

class _MoiEmptyStateState extends State<MoiEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildGraphic(BuildContext context) {
    final primary = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final bgSize = widget.imageSize + 28;

    if (widget.imagePath != null && widget.imagePath!.trim().isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: bgSize,
            height: bgSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.06),
            ),
          ),
          Image.asset(
            widget.imagePath!,
            width: widget.imageSize,
            height: widget.imageSize,
            fit: BoxFit.contain,
          ),
        ],
      );
    }

    if (widget.icon is Widget) {
      return widget.icon as Widget;
    }

    if (widget.icon is IconData) {
      return Icon(
        widget.icon as IconData,
        size: widget.imageSize * 0.7,
        color: primary.withValues(alpha: 0.85),
      );
    }

    if (widget.icon is List) {
      return HugeIcon(
        icon: widget.icon,
        color: primary.withValues(alpha: 0.85),
        size: widget.imageSize * 0.7,
        strokeWidth: 1.8,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget buildContent() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGraphic(context),
              const SizedBox(height: 18),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontFamily: 'EduQLDHand',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                    fontSize: 18,
                    fontFamily: 'Caveat',
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final content = buildContent();

    if (reduceMotion) return content;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: content),
    );
  }
}
