import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

import 'expandable_code_block.dart';

class ChatMarkdownBody extends StatelessWidget {
  final String data;
  final double fontSize;

  const ChatMarkdownBody({super.key, required this.data, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: _buildStyleSheet(context),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: fontSize,
          ),
          textScaleFactor: fontSize / 16.0,
        ),
        'code': _ChatCodeBlockBuilder(),
      },
      extensionSet: md.ExtensionSet(
        [...md.ExtensionSet.gitHubFlavored.blockSyntaxes, LatexBlockSyntax()],
        [...md.ExtensionSet.gitHubFlavored.inlineSyntaxes, LatexInlineSyntax()],
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = fontSize;

    return MarkdownStyleSheet(
      p: TextStyle(fontSize: f, height: 1.6, color: scheme.onSurface),
      h1: TextStyle(
        fontSize: f + 8,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: f + 5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: f + 3,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      h4: TextStyle(fontSize: f + 1, fontWeight: FontWeight.w700, color: scheme.onSurface),
      code: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: f - 2,
        color: scheme.primary,
        backgroundColor: scheme.primaryContainer.withOpacity(0.25),
      ),
      codeblockDecoration: const BoxDecoration(
        color: Color(0xFF0D1220),
      ),
      blockquote: TextStyle(
        color: scheme.onSurface.withOpacity(0.75),
        fontSize: f - 1,
        height: 1.6,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        border: Border(left: BorderSide(color: scheme.primary, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      listBullet: TextStyle(color: scheme.primary, fontSize: f),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline.withOpacity(0.5), width: 1)),
      ),
      a: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.none,
        fontWeight: FontWeight.w600,
      ),
      tableHead: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface),
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

class _ChatCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    final String? clazz = element.attributes['class'];
    final isBlock = clazz != null || code.contains('\n');
    if (!isBlock) return null;

    String? language;
    if (clazz != null && clazz.startsWith('language-')) {
      language = clazz.substring('language-'.length);
    }

    return ExpandableCodeBlock(code: code, language: language);
  }
}
