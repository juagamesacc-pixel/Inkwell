import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String filePath;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;
  final List<String> linkedNotes;
  final NoteType type;
  final bool isPinned;

  Note({
    String? id,
    required this.title,
    required this.content,
    required this.filePath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.tags = const [],
    this.linkedNotes = const [],
    this.type = NoteType.markdown,
    this.isPinned = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  int get wordCount =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  int get readingTime => (wordCount / 200).ceil();

  bool get hasContent => content.trim().isNotEmpty;

  Note copyWith({
    String? title,
    String? content,
    String? filePath,
    DateTime? modifiedAt,
    List<String>? tags,
    List<String>? linkedNotes,
    NoteType? type,
    bool? isPinned,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      linkedNotes: linkedNotes ?? this.linkedNotes,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags,
      'linkedNotes': linkedNotes,
      'type': type.name,
      'isPinned': isPinned,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'] ?? 'Untitled',
      content: map['content'] ?? '',
      filePath: map['filePath'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      modifiedAt: map['modifiedAt'] != null
          ? DateTime.tryParse(map['modifiedAt']) ?? DateTime.now()
          : DateTime.now(),
      tags: List<String>.from(map['tags'] ?? const []),
      linkedNotes: List<String>.from(map['linkedNotes'] ?? const []),
      type: NoteType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NoteType.markdown,
      ),
      isPinned: map['isPinned'] ?? false,
    );
  }
}

enum NoteType {
  markdown,
  chat,
  googleDocs,
}

extension NoteTypeX on NoteType {
  String get label {
    switch (this) {
      case NoteType.markdown:
        return 'Markdown';
      case NoteType.chat:
        return 'Chat';
      case NoteType.googleDocs:
        return 'Imported';
    }
  }
}
