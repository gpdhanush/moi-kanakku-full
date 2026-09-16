import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Modern empty / no-results state used across search and list screens.
class MoiEmptyState extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<List<dynamic>> icon;
  final Color? accentColor;

  const MoiEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = HugeIcons.strokeRoundedSearchRemove,
    this.accentColor,
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
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget buildContent() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xffE4E4E7)),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: widget.icon,
                  color: primary.withValues(alpha: 0.85),
                  size: 30,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: const Color(0xff18181B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: const Color(0xff71717A),
                    fontSize: 13,
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
