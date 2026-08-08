import '../models/note.dart';
import '../services/link_service.dart';

class MarkdownParser {
  /// Parses markdown content and extracts metadata
  static NoteMetadata parse(String content, {String? title}) {
    final links = LinkService.extractLinks(content);
    final tags = LinkService.extractTags(content);
    final wordCount = content.split(RegExp(r'\s+')).length;
    final readingTime = (wordCount / 200).ceil(); // minutes

    // Extract first heading as title if not provided
    String extractedTitle = title ?? '';
    if (extractedTitle.isEmpty) {
      final headingMatch = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
      if (headingMatch != null) {
        extractedTitle = headingMatch.group(1)!;
      }
    }

    // Extract sections
    final sections = _extractSections(content);

    return NoteMetadata(
      title: extractedTitle,
      links: links,
      tags: tags,
      wordCount: wordCount,
      readingTime: readingTime,
      sections: sections,
    );
  }

  static List<Section> _extractSections(String content) {
    final sections = <Section>[];
    final lines = content.split('\n');
    Section? currentSection;

    for (var line in lines) {
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        if (currentSection != null) {
          sections.add(currentSection);
        }
        currentSection = Section(
          level: headingMatch.group(1)!.length,
          title: headingMatch.group(2)!,
          content: '',
        );
      } else if (currentSection != null) {
        currentSection = currentSection.copyWith(
          content: '${currentSection.content}\n$line',
        );
      }
    }

    if (currentSection != null) {
      sections.add(currentSection);
    }

    return sections;
  }

  /// Converts markdown to plain text (strips formatting)
  static String toPlainText(String markdown) {
    var text = markdown;
    
    // Remove headings
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    
    // Remove bold/italic
    text = text.replaceAll(RegExp(r'\*{1,2}'), '');
    
    // Remove links
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
    
    // Remove images
    text = text.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), '');
    
    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '[Code Block]');
    
    // Remove inline code
    text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    
    // Remove blockquotes
    text = text.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    
    // Remove horizontal rules
    text = text.replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '');
    
    return text.trim();
  }
}

class NoteMetadata {
  final String title;
  final List<String> links;
  final List<String> tags;
  final int wordCount;
  final int readingTime;
  final List<Section> sections;

  NoteMetadata({
    required this.title,
    required this.links,
    required this.tags,
    required this.wordCount,
    required this.readingTime,
    required this.sections,
  });
}

class Section {
  final int level;
  final String title;
  final String content;

  Section({
    required this.level,
    required this.title,
    required this.content,
  });

  Section copyWith({String? content}) {
    return Section(
      level: level,
      title: title,
      content: content ?? this.content,
    );
  }
}
