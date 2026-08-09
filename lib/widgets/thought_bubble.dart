import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThoughtBubble extends StatefulWidget {
  final String thoughts;

  const ThoughtBubble({super.key, required this.thoughts});

  @override
  State<ThoughtBubble> createState() => _ThoughtBubbleState();
}

class _ThoughtBubbleState extends State<ThoughtBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.thoughts.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.tertiary.withOpacity(0.1),
                scheme.tertiary.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: scheme.tertiary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: scheme.tertiary.withOpacity(0.15),
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            size: 12,
                            color: scheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinking',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.tertiary,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: scheme.tertiary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Text(
                  widget.thoughts,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: scheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
    ).slideY(
      begin: -0.05,
      end: 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
