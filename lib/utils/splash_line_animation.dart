import 'package:flutter/material.dart';

class SplashLineAnimation extends StatefulWidget {
  final double height;
  final Color fillColor;
  final Color unfilledColor;
  final Duration duration;

  const SplashLineAnimation({
    super.key,
    this.height = 10,
    this.fillColor = Colors.white,
    this.unfilledColor = const Color(0xFF444444),
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<SplashLineAnimation> createState() => _SplashLineAnimationState();
}

class _SplashLineAnimationState extends State<SplashLineAnimation>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(); // loop infinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.unfilledColor,
            borderRadius: BorderRadius.circular(widget.height),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: maxWidth * _controller.value, // left → right fill
                      decoration: BoxDecoration(
                        color: widget.fillColor,
                        borderRadius: BorderRadius.circular(widget.height),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}
