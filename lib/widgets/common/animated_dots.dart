import 'package:flutter/material.dart';

/// Displays three animated dots appearing one by one in a loop
/// Used for polling states like "Waiting for scan" or "Finishing"
///
/// Example:
///   AnimatedDots(color: Colors.white, fontSize: 24)
class AnimatedDots extends StatefulWidget {
  final Color color;
  final double fontSize;

  const AnimatedDots({
    super.key,
    this.color = Colors.white,
    this.fontSize = 24,
  });

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _dotCount = (_dotCount + 1) % 4; // cycles: 0 → 1 → 2 → 3 → 0
            });
            _controller.forward(from: 0);
          }
        });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Fixed width so surrounding text doesn't shift when dots appear/disappear
      width: widget.fontSize * 1.8,
      child: Text(
        '.' * _dotCount,
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
