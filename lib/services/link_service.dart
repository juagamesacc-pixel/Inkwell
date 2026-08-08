import '../models/note.dart';

class LinkService {
  /// Extracts [[wiki-style links]] from content
  static List<String> extractLinks(String content) {
    final RegExp linkRegex = RegExp(r'\[\[(.+?)\]\]');
    final matches = linkRegex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Extracts tags from content
  static List<String> extractTags(String content) {
    final RegExp tagRegex = RegExp(r'#[\w]+');
    final matches = tagRegex.allMatches(content);
    return matches.map((m) => m.group(0)!).toSet().toList();
  }

  /// Builds link graph from all notes
  static Map<String, List<String>> buildLinkGraph(List<Note> notes) {
    final graph = <String, List<String>>{};
    
    for (var note in notes) {
      final links = extractLinks(note.content);
      graph[note.id] = links.map((linkTitle) {
        final target = notes.firstWhere(
          (n) => n.title.toLowerCase() == linkTitle.toLowerCase(),
          orElse: () => Note(
            id: 'unknown',
            title: linkTitle,
            content: '',
            filePath: '',
          ),
        );
        return target.id;
      }).toList();
    }
    
    return graph;
  }

  /// Gets backlinks for a note
  static List<Note> getBacklinks(Note note, List<Note> allNotes) {
    return allNotes.where((n) {
      if (n.id == note.id) return false;
      final links = extractLinks(n.content);
      return links.any((link) => 
        link.toLowerCase() == note.title.toLowerCase());
    }).toList();
  }

  /// Updates content links based on note title change
  static String updateLinksInContent(
    String content, 
    String oldTitle, 
    String newTitle,
  ) {
    return content.replaceAll('[[$oldTitle]]', '[[$newTitle]]');
  }
}
