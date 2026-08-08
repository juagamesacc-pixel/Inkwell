import 'package:flutter/material.dart';
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
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Note copyWith({
    String? title,
    String? content,
    String? filePath,
    DateTime? modifiedAt,
    List<String>? tags,
    List<String>? linkedNotes,
    NoteType? type,
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
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      filePath: map['filePath'],
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
      tags: List<String>.from(map['tags'] ?? []),
      linkedNotes: List<String>.from(map['linkedNotes'] ?? []),
      type: NoteType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NoteType.markdown,
      ),
    );
  }
}

enum NoteType {
  markdown,
  chat,
  googleDocs,
}
