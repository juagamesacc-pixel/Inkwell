import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomMarkdownBuilder extends MarkdownWidget {
  final String data;

  const CustomMarkdownBuilder({
    super.key,
    required this.data,
    MarkdownStyleSheet? stylesheet,
    bool selectable = true,
    VoidCallback? onLinkTap,
  }) : super(
          data: data,
          selectable: selectable,
          onTapLink: (text, href, title) {
            onLinkTap?.call();
          },
        );

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: _buildStyleSheet(context),
      builders: {
        'code': _CodeBlockBuilder(),
      },
      onTapLink: (text, href, title) {
        // Handle internal wiki links
        if (text.startsWith('[[') && text.endsWith(']]')) {
          // Navigate to internal note
        }
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h1: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      code: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      ),
      codeblockDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      blockquote: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      listBullet: TextStyle(
        color: Theme.of(context).colorScheme.primary,
      ),
      a: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      tableBody: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      tableBorder: TableBorder.all(
        color: Theme.of(context).dividerTheme.color ?? Colors.grey,
      ),
      tableCellsPadding: const EdgeInsets.all(8),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          element.textContent,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
