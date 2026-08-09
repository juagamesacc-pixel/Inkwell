import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomMarkdownBuilder extends StatelessWidget {
  final String data;
  final ValueChanged<String>? onLinkTap;

  const CustomMarkdownBuilder({
    super.key,
    required this.data,
    this.onLinkTap,
  });

  /// Converts `[[Wiki Links]]` into regular links so they render and are
  /// tappable, while keeping a friendly label.
  static String preprocessWikiLinks(String content) {
    final pattern = RegExp(r'\[\[([^\]]+)\]\]');
    return content.replaceAllMapped(pattern, (m) {
      final target = m.group(1)!.trim();
      return '[$target](#$target)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: preprocessWikiLinks(data),
      selectable: true,
      styleSheet: _buildStyleSheet(context),
      builders: {
        'code': _CodeBlockBuilder(),
      },
      onTapLink: (text, href, title) {
        final target = href?.startsWith('#') == true
            ? Uri.decodeComponent(href!.substring(1))
            : (text ?? href ?? '');
        onLinkTap?.call(target);
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        height: 1.7,
        color: scheme.onSurface,
      ),
      h1: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: scheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      h4: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      code: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 13.5,
        color: scheme.primary,
        backgroundColor: scheme.primaryContainer.withOpacity(0.25),
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1220) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
      ),
      blockquote: TextStyle(
        color: scheme.onSurface.withOpacity(0.75),
        fontSize: 15,
        height: 1.6,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        border: Border(
          left: BorderSide(color: scheme.primary, width: 4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      listBullet: TextStyle(color: scheme.primary, fontSize: 16),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      a: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.none,
        fontWeight: FontWeight.w600,
      ),
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      tableBody: TextStyle(color: scheme.onSurface),
      tableBorder: TableBorder.all(
        color: scheme.outline.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      tableCellsPadding: const EdgeInsets.all(10),
      tableColumnWidth: const FlexColumnWidth(),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = element.textContent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1220) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  'Code',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                height: 1.6,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
