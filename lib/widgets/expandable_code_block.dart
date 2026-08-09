import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_highlight/languages/all.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

Highlight? _cachedHighlight;

Highlight get _highlightInstance =>
    _cachedHighlight ??= Highlight()..registerLanguages(builtinAllLanguages);

class ExpandableCodeBlock extends StatefulWidget {
  final String code;
  final String? language;

  const ExpandableCodeBlock({super.key, required this.code, this.language});

  @override
  State<ExpandableCodeBlock> createState() => _ExpandableCodeBlockState();
}

class _ExpandableCodeBlockState extends State<ExpandableCodeBlock> {
  bool _expanded = false;

  String get _label {
    final lang = widget.language;
    if (lang == null || lang.isEmpty) return 'Code';
    return lang;
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildBody(context) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: [
              const Icon(Icons.code_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrainsMono',
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _copy,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: 13,
      height: 1.6,
      color: Color(0xFFABB2BF),
    );

    final result = _highlightCode(widget.code, widget.language);
    final renderer = TextSpanRenderer(baseStyle, atomOneDarkTheme);
    result.render(renderer);
    final span = renderer.span ?? TextSpan(text: widget.code, style: baseStyle);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(14),
      child: Text.rich(span, style: baseStyle),
    );
  }
}

HighlightResult _highlightCode(String code, String? language) {
  final highlight = _highlightInstance;
  if (language != null && language.isNotEmpty && highlight.getLanguage(language) != null) {
    return highlight.highlight(code: code, language: language);
  }
  return highlight.highlightAuto(code);
}
