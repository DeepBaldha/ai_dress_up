import 'dart:async';
import 'package:flutter/material.dart';

import '../consts.dart';

class DeepPressUnpress extends StatefulWidget {
  final double height;
  final double width;
  final Widget child;
  final String? image;
  final Function() onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? imageColor;

  const DeepPressUnpress({
    super.key,
    required this.height,
    required this.width,
    required this.child,
    required this.onTap,
    this.image,
    this.margin,
    this.padding,
    this.imageColor,
  });

  @override
  State<DeepPressUnpress> createState() => _DeepPressUnpressState();
}

class _DeepPressUnpressState extends State<DeepPressUnpress>
    with SingleTickerProviderStateMixin {
  bool isPress = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      isPress = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      isPress = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      isPress = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              height: widget.height,
              width: widget.width,
              margin: widget.margin,
              padding: widget.padding,
              decoration: widget.image != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(defaultImagePath + widget.image!),
                        fit: BoxFit.fill,
                        colorFilter: widget.imageColor != null
                            ? ColorFilter.mode(
                                widget.imageColor!,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    )
                  : null,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class NewDeepPressUnpress extends StatefulWidget {
  final Widget child;
  final Function() onTap;
  final String? image;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? imageColor;
  final double? height;
  final double? width;

  const NewDeepPressUnpress({
    super.key,
    required this.child,
    required this.onTap,
    this.image,
    this.margin,
    this.padding,
    this.imageColor,
    this.height,
    this.width,
  });

  @override
  State<NewDeepPressUnpress> createState() => _NewDeepPressUnpressState();
}

class _NewDeepPressUnpressState extends State<NewDeepPressUnpress>
    with SingleTickerProviderStateMixin {
  bool isPress = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      isPress = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    // Don't immediately reverse the animation
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          isPress = false;
        });
        _animationController.reverse();
      }
    });
  }

  void _handleTapCancel() {
    setState(() {
      isPress = false;
    });
    _animationController.reverse();
  }

  void _handleTap() {
    widget.onTap();
    // Ensure the opacity effect is visible for taps
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          isPress = false;
        });
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              height: widget.height,
              width: widget.width,
              margin: widget.margin,
              padding: widget.padding,
              decoration: widget.image != null
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(defaultImagePath + widget.image!),
                        fit: BoxFit.fill,
                        colorFilter: widget.imageColor != null
                            ? ColorFilter.mode(
                                widget.imageColor!,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    )
                  : null,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
