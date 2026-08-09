import 'dart:ui';
import 'package:flutter/material.dart';

/// A polished frosted-glass container with an inner highlight border,
/// optional gradient and layered shadows.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Gradient? overlayGradient;
  final bool animated;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 22,
    this.opacity = 0.18,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.shadows,
    this.onTap,
    this.overlayGradient,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(22);

    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF64748B))
                    .withValues(alpha: isDark ? 0.35 : 0.14),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.06 : 0.05),
                blurRadius: 60,
                offset: const Offset(0, 0),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: overlayGradient ??
                  (gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: opacity),
                                Colors.white.withValues(alpha: opacity * 0.45),
                              ]
                            : [
                                Colors.white.withValues(alpha: opacity * 1.8),
                                Colors.white.withValues(alpha: opacity * 0.9),
                              ],
                      )),
              borderRadius: radius,
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.09 : 0.22),
                    width: 1,
                  ),
            ),
            child: Stack(
              children: [
                // Glossy top highlight.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 56,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(radius.topLeft.x),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.06 : 0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }

    return card;
  }
}
