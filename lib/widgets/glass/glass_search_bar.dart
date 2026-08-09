import 'dart:ui';
import 'package:flutter/material.dart';

class GlassSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const GlassSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search notes...',
  });

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(_isFocused ? 0.13 : 0.07),
                      Colors.white.withOpacity(_isFocused ? 0.07 : 0.035),
                    ]
                  : [
                      Colors.white.withOpacity(_isFocused ? 0.95 : 0.8),
                      Colors.white.withOpacity(_isFocused ? 0.85 : 0.6),
                    ],
            ),
            border: Border.all(
              color: _isFocused
                  ? accent.withOpacity(0.7)
                  : Colors.white.withOpacity(isDark ? 0.1 : 0.35),
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? accent.withOpacity(0.22)
                    : Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                blurRadius: _isFocused ? 26 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: _isFocused
                      ? LinearGradient(
                          colors: [accent.withOpacity(0.25), accent.withOpacity(0.1)],
                        )
                      : null,
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: _isFocused
                      ? accent
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.35),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
                  },
                )
              else if (_isFocused)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
