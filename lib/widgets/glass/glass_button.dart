import 'dart:ui';
import 'package:flutter/material.dart';

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool enabled;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final enabled = widget.enabled && widget.onPressed != null;

    final gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            Color.lerp(accent, const Color(0xFF8B5CF6), 0.45)!,
          ],
        );

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              _controller.forward();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: enabled
          ? (_) {
              _controller.reverse();
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled
          ? () {
              _controller.reverse();
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.width,
                  height: widget.height,
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: gradient,
                    border: Border.all(
                      color: Colors.white.withOpacity(
                          enabled ? (isDark ? 0.18 : 0.35) : 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent
                            .withOpacity(enabled ? 0.35 : 0.1)
                            .withOpacity(_isPressed ? 0.18 : 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      if (enabled)
                        BoxShadow(
                          color: gradient.colors.last.withOpacity(0.22),
                          blurRadius: 32,
                          offset: const Offset(0, 0),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : DefaultTextStyle.merge(
                                style: const TextStyle(color: Colors.white),
                                child: widget.child,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
