import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedEqualizer extends StatefulWidget {
  final bool isPlaying;
  final Color? color;
  final double height;
  final double barWidth;

  const AnimatedEqualizer({
    super.key,
    required this.isPlaying,
    this.color,
    this.height = 18,
    this.barWidth = 3,
  });

  @override
  State<AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppTheme.secondaryCyan;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          double factor = widget.isPlaying
              ? (sin((_controller.value * 2 * pi) + (index * 1.2)).abs() * 0.7 + 0.3)
              : 0.2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: widget.barWidth,
            height: widget.height * factor,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(widget.barWidth / 2),
            ),
          );
        }),
      ),
    );
  }
}
