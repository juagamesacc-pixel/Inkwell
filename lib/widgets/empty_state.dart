import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable, animated empty-state with an SVG illustration.
class EmptyState extends StatelessWidget {
  final String illustration;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.illustration,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              illustration,
              width: 240,
              height: 180,
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1),
                    curve: Curves.easeOutBack),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: colorScheme.onSurface,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.08, end: 0),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08, end: 0),
            ],
            if (action != null) ...[
              const SizedBox(height: 28),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
