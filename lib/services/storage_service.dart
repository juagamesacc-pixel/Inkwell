import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/chat_message.dart';

class StorageService extends ChangeNotifier {
  static const String _notesDir = 'notes';
  static const String _chatsDir = 'chats';
  static const String _metadataFile = 'metadata.json';
  
  Directory? _appDir;
  Directory? _notesDirectory;
  Directory? _chatsDirectory;
  List<Note> _notes = [];
  
  List<Note> get notes => _notes;

  Future<void> init() async {
    _appDir = await getApplicationDocumentsDirectory();
    _notesDirectory = Directory('${_appDir!.path}/$_notesDir');
    _chatsDirectory = Directory('${_appDir!.path}/$_chatsDir');
    
    await _notesDirectory!.create(recursive: true);
    await _chatsDirectory!.create(recursive: true);
    
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    final metadataFile = File('${_appDir!.path}/$_metadataFile');
    if (await metadataFile.exists()) {
      final data = jsonDecode(await metadataFile.readAsString());
      _notes = (data as List).map((e) => Note.fromMap(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveMetadata() async {
    final metadataFile = File('${_appDir!.path}/$_metadataFile');
    await metadataFile.writeAsString(jsonEncode(_notes.map((e) => e.toMap()).toList()));
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

  Future<void> updateNote(Note note, {String? content, String? title}) async {
    final updatedNote = note.copyWith(
      content: content ?? note.content,
      title: title ?? note.title,
      modifiedAt: DateTime.now(),
    );
    
    final file = File(note.filePath);
    await file.writeAsString(updatedNote.content);
    
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
    }
    
    await _saveMetadata();
    notifyListeners();
  }

  Future<void> deleteNote(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    _notes.removeWhere((n) => n.id == note.id);
    await _saveMetadata();
    notifyListeners();
  }

  Future<String> readNoteContent(Note note) async {
    final file = File(note.filePath);
    if (await file.exists()) {
      return await file.readAsString();
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
    
    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<Note> getNotesByType(NoteType type) {
    return _notes.where((n) => n.type == type).toList();
  }

  Future<String> getWorkspacePath() async {
    return '/sdcard/project/MD-Notes';
  }
}
