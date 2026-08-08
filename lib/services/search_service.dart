import '../models/note.dart';

class SearchService {
  /// Full-text search across notes
  static List<Note> search(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    
    final lowerQuery = query.toLowerCase();
    final results = <_SearchResult>[];
    
    for (var note in notes) {
      double score = 0;
      
      // Title match (highest weight)
      if (note.title.toLowerCase().contains(lowerQuery)) {
        score += 10;
        if (note.title.toLowerCase().startsWith(lowerQuery)) {
          score += 5;
        }
      }
      
      // Tag match
      for (var tag in note.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) {
          score += 7;
        }
      }
      
      // Content match
      final contentLower = note.content.toLowerCase();
      int contentMatches = 0;
      int startIndex = 0;
      while (true) {
        final index = contentLower.indexOf(lowerQuery, startIndex);
        if (index == -1) break;
        contentMatches++;
        startIndex = index + 1;
      }
      score += contentMatches * 2;
      
      if (score > 0) {
        results.add(_SearchResult(note: note, score: score));
      }
    }
    
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.map((r) => r.note).toList();
  }

  /// Search with context snippets
  static List<SearchResultWithSnippet> searchWithSnippets(
    List<Note> notes, 
    String query, 
    {int snippetLength = 100}
  ) {
    if (query.isEmpty) {
      return notes.map((n) => SearchResultWithSnippet(note: n)).toList();
    }
    
    final lowerQuery = query.toLowerCase();
    final results = <SearchResultWithSnippet>[];
    
    for (var note in notes) {
      final contentLower = note.content.toLowerCase();
      final index = contentLower.indexOf(lowerQuery);
      
      if (index != -1 || note.title.toLowerCase().contains(lowerQuery)) {
        String? snippet;
        if (index != -1) {
          final start = (index - snippetLength ~/ 2).clamp(0, note.content.length);
          final end = (index + query.length + snippetLength ~/ 2)
              .clamp(0, note.content.length);
          snippet = note.content.substring(start, end);
          if (start > 0) snippet = '...$snippet';
          if (end < note.content.length) snippet = '$snippet...';
        }
        
        results.add(SearchResultWithSnippet(
          note: note,
          snippet: snippet,
          matchIndex: index,
        ));
      }
    }
    
    return results;
  }
}

class _SearchResult {
  final Note note;
  final double score;
  
  _SearchResult({required this.note, required this.score});
}

class SearchResultWithSnippet {
  final Note note;
  final String? snippet;
  final int? matchIndex;
  
  SearchResultWithSnippet({
    required this.note,
    this.snippet,
    this.matchIndex,
  });
}
