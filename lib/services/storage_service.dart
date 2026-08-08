import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../services/search_service.dart';
import 'link_service.dart';

class StorageService extends ChangeNotifier {
  static const String _notesDir = 'notes';
  static const String _chatsDir = 'chats';
  static const String _exportsDir = 'exports';
  static const String _metadataFile = 'metadata.json';

  Directory? _appDir;
  Directory? _notesDirectory;
  Directory? _chatsDirectory;
  Directory? _exportsDirectory;
  List<Note> _notes = [];

  List<Note> get notes => List.unmodifiable(_notes);

  Directory? get exportsDirectory => _exportsDirectory;

  int get totalWordCount =>
      _notes.fold(0, (sum, n) => sum + n.wordCount);

  int get totalLinks => _notes.fold(
      0, (sum, n) => sum + LinkService.extractLinks(n.content).length);

  Future<void> init() async {
    _appDir = await getApplicationDocumentsDirectory();
    _notesDirectory = Directory('${_appDir!.path}/$_notesDir');
    _chatsDirectory = Directory('${_appDir!.path}/$_chatsDir');
    _exportsDirectory = Directory('${_appDir!.path}/$_exportsDir');

    await _notesDirectory!.create(recursive: true);
    await _chatsDirectory!.create(recursive: true);
    await _exportsDirectory!.create(recursive: true);

    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    final metadataFile = File('${_appDir!.path}/$_metadataFile');
    if (await metadataFile.exists()) {
      try {
        final data = jsonDecode(await metadataFile.readAsString());
        _notes = (data as List).map((e) => Note.fromMap(e)).toList();
      } catch (_) {
        _notes = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveMetadata() async {
    final metadataFile = File('${_appDir!.path}/$_metadataFile');
    await metadataFile.writeAsString(
      jsonEncode(_notes.map((e) => e.toMap()).toList()),
    );
  }

  Future<Note> createNote({
    required String title,
    String content = '',
    NoteType type = NoteType.markdown,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = '$id.md';
    final filePath = type == NoteType.chat || type == NoteType.googleDocs
        ? '${_chatsDirectory!.path}/$fileName'
        : '${_notesDirectory!.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(content);

    final note = Note(
      id: id,
      title: title,
      content: content,
      filePath: filePath,
      type: type,
    );

    _notes.insert(0, note);
    await _saveMetadata();
    notifyListeners();
    return note;
  }

  Future<void> updateNote(Note note,
      {String? content, String? title, List<String>? tags}) async {
    final updatedNote = note.copyWith(
      content: content ?? note.content,
      title: title ?? note.title,
      tags: tags ?? note.tags,
      modifiedAt: DateTime.now(),
    );

    final file = File(note.filePath);
    try {
      await file.writeAsString(updatedNote.content);
    } catch (_) {
      // The file may not exist yet (e.g. restored metadata only).
    }

    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
    }

    await _saveMetadata();
    notifyListeners();
  }

  Future<void> togglePin(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    _notes[index] = note.copyWith(isPinned: !note.isPinned);
    await _saveMetadata();
    notifyListeners();
  }

  Future<void> deleteNote(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
    _notes.removeWhere((n) => n.id == note.id);
    await _saveMetadata();
    notifyListeners();
  }

  Future<String> readNoteContent(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  Future<List<ChatMessage>> readChatMessages(Note note) async {
    final content = await readNoteContent(note);
    if (content.isEmpty) return [];

    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ChatMessage.fromJsonMap(json);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChatMessages(Note note, List<ChatMessage> messages) async {
    final json = ChatMessage.toJsonMap(messages);
    final content = jsonEncode(json);
    await updateNote(note, content: content);
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    return SearchService.search(_notes, query);
  }

  List<Note> getNotesByType(NoteType type) {
    return _notes.where((n) => n.type == type).toList();
  }

  /// Sorted copy: pinned first, then by modified date.
  List<Note> sortedNotes() {
    final list = List<Note>.from(_notes);
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.modifiedAt.compareTo(a.modifiedAt);
    });
    return list;
  }

  // ---- Import helpers ------------------------------------------------

  Future<Note> importMarkdown(String fileName, String content) async {
    final title = fileName.replaceAll(RegExp(r'\.md$'), '').trim();
    return createNote(title: title.isEmpty ? 'Untitled' : title, content: content);
  }

  Future<Note> importChatJson(String fileName, String content) async {
    final title = fileName.replaceAll(RegExp(r'\.json$'), '').trim();
    return createNote(
      title: title.isEmpty ? 'Chat' : title,
      content: content,
      type: NoteType.chat,
    );
  }

  Future<Note> importGeminiExport(String fileName, String content) async {
    final title = fileName.replaceAll(RegExp(r'\.json$'), '').trim();
    return createNote(
      title: title.isEmpty ? 'Import' : title,
      content: content,
      type: NoteType.googleDocs,
    );
  }

  // ---- Export helpers ------------------------------------------------

  Future<File> exportNoteToFile(Note note) async {
    final content = await readNoteContent(note);
    final safeTitle = note.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final file = File('${_exportsDirectory!.path}/${safeTitle.isEmpty ? 'note' : safeTitle}.md');
    await file.writeAsString(content);
    return file;
  }

  Future<File> exportChatToFile(Note note) async {
    final messages = await readChatMessages(note);
    final json = ChatMessage.toJsonMap(messages);
    final content = const JsonEncoder.withIndent('  ').convert(json);
    final safeTitle = note.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final file = File('${_exportsDirectory!.path}/${safeTitle.isEmpty ? 'chat' : safeTitle}.json');
    await file.writeAsString(content);
    return file;
  }
}
