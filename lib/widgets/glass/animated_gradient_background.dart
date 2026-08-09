import 'dart:math';
import 'package:flutter/material.dart';

/// A rich animated background made of a slowly-shifting gradient plus
/// floating, soft blurred orbs. Paints cheaply using radial gradients.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Orb> _orbs = [
    _Orb(color: const Color(0xFF6366F1), size: 320, phase: 0.0, speed: 1.0),
    _Orb(color: const Color(0xFFEC4899), size: 260, phase: 1.8, speed: 0.8),
    _Orb(color: const Color(0xFF14B8A6), size: 300, phase: 3.4, speed: 1.2),
    _Orb(color: const Color(0xFF8B5CF6), size: 200, phase: 4.9, speed: 0.7),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
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
    final colors = widget.colors ??
        (isDark
            ? [
                const Color(0xFF070A13),
                const Color(0xFF0C1120),
                const Color(0xFF101524),
                const Color(0xFF0A0E1A),
              ]
            : [
                const Color(0xFFF6F8FF),
                const Color(0xFFEEF2FF),
                const Color(0xFFFDF2F8),
                const Color(0xFFEFFAF5),
              ]);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * pi;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1 + 2 * sin(t * 0.7),
                -1 + 2 * cos(t * 0.7),
              ),
              end: Alignment(
                1 - 2 * sin(t * 0.7),
                1 - 2 * cos(t * 0.7),
              ),
              colors: colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final orb in _orbs)
                _buildOrb(orb, t, isDark, accent),
              // Soft sheen sweeping across the top.
              Positioned(
                top: -160,
                right: -120,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Container(
                    width: 480,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(240),
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: isDark ? 0.12 : 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrb(_Orb orb, double t, bool isDark, Color accent) {
    final x = sin(t * orb.speed + orb.phase);
    final y = cos(t * orb.speed + orb.phase * 1.3);

    return Positioned(
      left: 80 + x * 130,
      top: 70 + y * 110,
      width: orb.size,
      height: orb.size,
      child: Transform.translate(
        offset: Offset(sin(t * orb.speed) * 18, cos(t * orb.speed) * 18),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                orb.color.withValues(alpha: isDark ? 0.24 : 0.20),
                orb.color.withValues(alpha: isDark ? 0.06 : 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Orb {
  final Color color;
  final double size;
  final double phase;
  final double speed;

  const _Orb({
    required this.color,
    required this.size,
    required this.phase,
    required this.speed,
  });
}
