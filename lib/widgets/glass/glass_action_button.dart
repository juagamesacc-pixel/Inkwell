import 'dart:ui';
import 'package:flutter/material.dart';

/// A small frosted, tappable icon button used in app bars.
class GlassActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;
  final double size;

  const GlassActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.tooltip,
    this.size = 42,
  });

  @override
  State<GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<GlassActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.color ?? Theme.of(context).colorScheme.primary;

    Widget button = GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel:
          widget.onPressed == null ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _pressed
                      ? [accent.withOpacity(0.3), accent.withOpacity(0.18)]
                      : [accent.withOpacity(0.16), accent.withOpacity(0.07)],
                ),
                border: Border.all(
                  color: accent.withOpacity(_pressed ? 0.4 : 0.22),
                ),
                boxShadow: _pressed
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.28),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: 19,
                color: accent,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
