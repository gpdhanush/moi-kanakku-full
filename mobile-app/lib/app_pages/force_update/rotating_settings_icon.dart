import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Compact line-style settings gear with a continuous clockwise spin.
class RotatingSettingsIcon extends StatefulWidget {
  final Color color;
  final Color backgroundColor;
  final double iconSize;
  final double containerSize;
  final Duration duration;

  const RotatingSettingsIcon({
    super.key,
    required this.color,
    required this.backgroundColor,
    this.iconSize = 22,
    this.containerSize = 48,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<RotatingSettingsIcon> createState() => _RotatingSettingsIconState();
}

class _RotatingSettingsIconState extends State<RotatingSettingsIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation(MediaQuery.disableAnimationsOf(context));
  }

  void _syncAnimation(bool reduceMotion) {
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RotatingSettingsIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (_reduceMotion == false) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.containerSize,
      width: widget.containerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.backgroundColor,
      ),
      alignment: Alignment.center,
      child: _reduceMotion == true
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              size: widget.iconSize,
              color: widget.color,
              strokeWidth: 1.6,
            )
          : RotationTransition(
              turns: _controller,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                size: widget.iconSize,
                color: widget.color,
                strokeWidth: 1.6,
              ),
            ),
    );
  }
}
