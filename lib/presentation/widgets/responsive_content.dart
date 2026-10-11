import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 14,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}
