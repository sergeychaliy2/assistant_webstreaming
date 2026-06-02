import 'package:flutter/material.dart';

/// A round press target with subtle hover/press scale feedback.
/// Wraps any circular widget and unifies interaction behaviour across the app.
class CirclePressTarget extends StatefulWidget {
  const CirclePressTarget({
    super.key,
    required this.diameter,
    required this.child,
    this.enabled = true,
    this.onPressStart,
    this.onPressEnd,
    this.onTap,
    this.hoverScale = 1.03,
    this.pressScale = 0.96,
  });

  final double diameter;
  final Widget child;
  final bool enabled;
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressScale;

  @override
  State<CirclePressTarget> createState() => _CirclePressTargetState();
}

class _CirclePressTargetState extends State<CirclePressTarget> {
  bool _hover = false;
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  void _setHover(bool v) {
    if (_hover == v) return;
    setState(() => _hover = v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? widget.pressScale
        : _hover
            ? widget.hoverScale
            : 1.0;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: Listener(
        onPointerDown: (_) {
          if (!widget.enabled) return;
          _setPressed(true);
          widget.onPressStart?.call();
        },
        onPointerUp: (_) {
          if (!_pressed) return;
          _setPressed(false);
          widget.onPressEnd?.call();
          widget.onTap?.call();
        },
        onPointerCancel: (_) {
          if (!_pressed) return;
          _setPressed(false);
          widget.onPressEnd?.call();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: SizedBox.square(
            dimension: widget.diameter,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
