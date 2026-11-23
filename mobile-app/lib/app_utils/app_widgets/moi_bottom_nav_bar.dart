import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

class MoiBottomNavItem {
  final List<List<dynamic>> icon;
  final String label;

  const MoiBottomNavItem({required this.icon, required this.label});
}

/// Full-width bottom menu bar for the main app shell.
///
/// With four items and an [onAddTap], the bar renders a raised diamond "+"
/// button that sits in a smooth V-shaped notch cut into the bar's top edge.
class MoiBottomNavBar extends StatelessWidget {
  /// Content height of the menu row (excluding system bottom inset).
  static const double barHeight = 72;

  /// Kept for callers that previously padded above the floating pill.
  static const double bottomGap = 0;

  /// Space above the bar reserved for the raised "+" button.
  static const double _overflowTop = 30;

  /// Side of the (unrotated) rounded square that forms the "+" diamond.
  static const double _diamondSide = 44;
  static const double _diamondRadius = 14;

  /// Vertical offset of the diamond's centre below the bar's top edge.
  static const double _diamondCenterY = 2;

  /// Gap between the diamond and the notch edge.
  static const double _notchGap = 6;

  static const double _barCornerRadius = 28;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MoiBottomNavItem> items;
  final VoidCallback? onAddTap;

  const MoiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onAddTap,
  });

  /// Space pages / FABs should leave clear above the bottom bar.
  static double clearanceOf(BuildContext context) {
    return barHeight + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Width/height of the diamond's bounding box once rotated 45°.
  static double get _diamondExtent => _diamondSide * math.sqrt2;

  /// Depth of the sharp V that the notch is rounded from.
  static double get _notchDepth =>
      _diamondCenterY + _diamondSide / math.sqrt2 + _notchGap * math.sqrt2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final isCenterAddLayout = onAddTap != null && items.length == 4;
    final topOffset = isCenterAddLayout ? _overflowTop : 0.0;

    // Slot layout: with the centre "+" there are five equal slots and the
    // middle one stays empty for the button.
    final slotCount = isCenterAddLayout ? 5 : items.length;
    int slotFor(int index) =>
        isCenterAddLayout && index >= 2 ? index + 1 : index;

    return SizedBox(
      height: topOffset + barHeight + bottomInset,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: topOffset,
            bottom: 0,
            child: CustomPaint(
              painter: _NotchedBarPainter(
                color: colors.surface,
                shadowColor: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.charcoal.withValues(alpha: 0.07),
                borderColor: isDark ? colors.border : null,
                cornerRadius: _barCornerRadius,
                notchDepth: isCenterAddLayout ? _notchDepth : 0,
              ),
              child: ClipPath(
                clipper: _NotchedBarClipper(
                  cornerRadius: _barCornerRadius,
                  notchDepth: isCenterAddLayout ? _notchDepth : 0,
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: SizedBox(
                    height: barHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final slotWidth = constraints.maxWidth / slotCount;
                        return Stack(
                          children: [
                            if (currentIndex >= 0 &&
                                currentIndex < items.length)
                              _SelectionPill(
                                index: currentIndex,
                                slotLeft: slotFor(currentIndex) * slotWidth,
                                slotWidth: slotWidth,
                                color: colors.moiReceivedSoft,
                                reduceMotion: reduceMotion,
                              ),
                            Row(
                              children: List.generate(slotCount, (slot) {
                                final index = isCenterAddLayout
                                    ? (slot == 2
                                          ? -1
                                          : (slot > 2 ? slot - 1 : slot))
                                    : slot;
                                if (index < 0) {
                                  return const Expanded(
                                    child: SizedBox.shrink(),
                                  );
                                }
                                return Expanded(
                                  child: _MoiBottomNavTile(
                                    item: items[index],
                                    selected: index == currentIndex,
                                    active: colors.iconActive,
                                    inactive: colors.iconDefault,
                                    reduceMotion: reduceMotion,
                                    onTap: () => onTap(index),
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isCenterAddLayout)
            Positioned(
              left: 0,
              right: 0,
              top: topOffset + _diamondCenterY - _diamondExtent / 2,
              height: _diamondExtent,
              child: Center(
                child: _AddDiamondButton(
                  side: _diamondSide,
                  radius: _diamondRadius,
                  color: colors.iconActive,
                  iconColor: isDark ? colors.onPrimary : AppColors.white,
                  reduceMotion: reduceMotion,
                  onTap: onAddTap!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bar outline: rounded top corners plus an optional V notch whose sides run
/// at 45° to hug the diamond button.
Path _notchedBarOutline(Size size, double cornerRadius, double notchDepth) {
  final w = size.width;
  final h = size.height;
  final r = cornerRadius;
  final path = Path()
    ..moveTo(0, h)
    ..lineTo(0, r)
    ..arcToPoint(Offset(r, 0), radius: Radius.circular(r));

  if (notchDepth > 0) {
    final cx = w / 2;
    final d = notchDepth;
    const shoulder = 12.0; // rounding of the notch's top corners
    const bottom = 14.0; // rounding of the notch's lowest point
    final s = shoulder / math.sqrt2;
    final b = bottom / math.sqrt2;
    path
      ..lineTo(cx - d - shoulder, 0)
      ..quadraticBezierTo(cx - d, 0, cx - d + s, s)
      ..lineTo(cx - b, d - b)
      ..quadraticBezierTo(cx, d, cx + b, d - b)
      ..lineTo(cx + d - s, s)
      ..quadraticBezierTo(cx + d, 0, cx + d + shoulder, 0);
  }

  path
    ..lineTo(w - r, 0)
    ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
    ..lineTo(w, h)
    ..close();
  return path;
}

class _NotchedBarClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchDepth;

  const _NotchedBarClipper({
    required this.cornerRadius,
    required this.notchDepth,
  });

  @override
  Path getClip(Size size) => _notchedBarOutline(size, cornerRadius, notchDepth);

  @override
  bool shouldReclip(_NotchedBarClipper old) =>
      old.cornerRadius != cornerRadius || old.notchDepth != notchDepth;
}

/// Paints the bar body along [_notchedBarOutline] with a soft shadow.
class _NotchedBarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final Color? borderColor;
  final double cornerRadius;
  final double notchDepth;

  const _NotchedBarPainter({
    required this.color,
    required this.shadowColor,
    required this.borderColor,
    required this.cornerRadius,
    required this.notchDepth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _notchedBarOutline(size, cornerRadius, notchDepth);

    canvas.drawPath(
      path.shift(const Offset(0, -2)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(path, Paint()..color = color);

    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.color != color ||
      old.shadowColor != shadowColor ||
      old.borderColor != borderColor ||
      old.cornerRadius != cornerRadius ||
      old.notchDepth != notchDepth;
}

/// Tinted rounded pill that slides to the selected slot and pops in with a
/// slight scale each time the selection changes.
class _SelectionPill extends StatelessWidget {
  final int index;
  final double slotLeft;
  final double slotWidth;
  final Color color;
  final bool reduceMotion;

  const _SelectionPill({
    required this.index,
    required this.slotLeft,
    required this.slotWidth,
    required this.color,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    const verticalInset = AppSpacing.xxs + 3;
    final width = math.min(slotWidth - AppSpacing.xs, 76.0);

    return AnimatedPositioned(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      left: slotLeft + (slotWidth - width) / 2,
      width: width,
      top: verticalInset,
      bottom: verticalInset,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(index),
        tween: Tween(begin: reduceMotion ? 1 : 0.82, end: 1),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

class _MoiBottomNavTile extends StatelessWidget {
  final MoiBottomNavItem item;
  final bool selected;
  final Color active;
  final Color inactive;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _MoiBottomNavTile({
    required this.item,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final color = selected ? active : inactive;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: duration,
              curve: Curves.easeOutBack,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: duration,
                builder: (context, value, _) => HugeIcon(
                  icon: item.icon,
                  color: value ?? color,
                  size: 22,
                  strokeWidth: selected ? 2.0 : 1.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs + 1),
            AnimatedDefaultTextStyle(
              duration: duration,
              curve: Curves.easeOutCubic,
              style: AppTypography.label.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
                height: 1.1,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raised rounded-diamond "+" button with a soft glow. Pops in on first
/// build and squishes/bounces on press.
class _AddDiamondButton extends StatefulWidget {
  final double side;
  final double radius;
  final Color color;
  final Color iconColor;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _AddDiamondButton({
    required this.side,
    required this.radius,
    required this.color,
    required this.iconColor,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_AddDiamondButton> createState() => _AddDiamondButtonState();
}

class _AddDiamondButtonState extends State<_AddDiamondButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final Animation<double> _entranceScale = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutBack,
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final top = Color.lerp(color, AppColors.white, 0.12)!;
    final bottom = Color.lerp(color, AppColors.charcoal, 0.14)!;
    final extent = widget.side * math.sqrt2;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: SizedBox(
          width: extent,
          height: extent,
          child: ScaleTransition(
            scale: _entranceScale,
            child: AnimatedScale(
              scale: _pressed ? 0.86 : 1,
              duration: widget.reduceMotion
                  ? Duration.zero
                  : Duration(milliseconds: _pressed ? 110 : 320),
              curve: _pressed ? Curves.easeOut : Curves.elasticOut,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: widget.side,
                      height: widget.side,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.radius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [top, bottom],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.38),
                            blurRadius: 18,
                            offset: const Offset(4, 4),
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.16),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _pressed ? 0.125 : 0,
                    duration: widget.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: widget.iconColor,
                      size: 26,
                      strokeWidth: 2.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
