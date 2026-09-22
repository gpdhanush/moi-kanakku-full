import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class VoiceListeningIndicator extends StatefulWidget {
  final bool active;
  final Color color;
  final double size;

  const VoiceListeningIndicator({
    super.key,
    required this.active,
    required this.color,
    this.size = 24,
  });

  @override
  State<VoiceListeningIndicator> createState() =>
      _VoiceListeningIndicatorState();
}

class _VoiceListeningIndicatorState extends State<VoiceListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant VoiceListeningIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return HugeIcon(
        icon: HugeIcons.strokeRoundedMic01,
        color: widget.color,
        size: widget.size,
        strokeWidth: 1.9,
      );
    }

    return SizedBox(
      width: widget.size + 16,
      height: widget.size + 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * math.pi * 2;
          final pulse = (math.sin(phase) + 1) / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(1.0 + pulse * 0.28, 0.10 + pulse * 0.08),
              _ring(0.76 + pulse * 0.16, 0.16 + pulse * 0.08),
              Container(
                width: widget.size + 4,
                height: widget.size + 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMic02,
                    color: widget.color,
                    size: widget.size * 0.68,
                    strokeWidth: 2,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(3, (index) {
                    final barPhase = phase + index * 1.1;
                    final height = 3 + ((math.sin(barPhase) + 1) / 2) * 5;
                    return Container(
                      width: 2,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double scale, double opacity) {
    final diameter = (widget.size + 12) * scale;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }
}
