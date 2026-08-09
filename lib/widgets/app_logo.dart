import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Inkwell brand logo: an SVG glyph inside a gradient tile.
class AppLogo extends StatelessWidget {
  final double size;
  final double radius;

  const AppLogo({super.key, this.size = 48, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1B2233).withValues(alpha: 0.7),
                      const Color(0xFF10141F).withValues(alpha: 0.5),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.55),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/svg/inkwell_logo.svg',
            fit: BoxFit.contain,
            width: size * 0.7,
            height: size * 0.7,
          ),
        ),
      ),
    );
  }
}
