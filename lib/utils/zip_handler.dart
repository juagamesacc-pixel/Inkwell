import 'package:archive/archive.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';

class ZipHandler {
  /// Exports multiple notes to a zip file
  static Future<List<int>> exportNotes(List<Note> notes, StorageService storage) async {
    final archive = Archive();

    for (var note in notes) {
      final content = await storage.readNoteContent(note);
      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}.md';
      
      archive.addFile(ArchiveFile(
        'notes/$fileName',
        content.length,
        content.codeUnits,
      ));

      // Also save metadata
      final metadata = jsonEncode(note.toMap());
      archive.addFile(ArchiveFile(
        'metadata/${note.id}.json',
        metadata.length,
        metadata.codeUnits,
      ));
    }

    // Create a zip file
    final zipData = ZipEncoder().encode(archive);
    return zipData ?? [];
  }

  /// Exports a single note to markdown
  static Future<List<int>> exportSingleNote(Note note, StorageService storage) async {
    final content = await storage.readNoteContent(note);
    return content.codeUnits;
  }

  /// Exports chat to JSON
  static Future<List<int>> exportChatJson(
    Note note,
    List<ChatMessage> messages,
  ) async {
    final json = ChatMessage.toJsonMap(messages);
    final content = const JsonEncoder.withIndent('  ').convert(json);
    return content.codeUnits;
  }

  /// Imports notes from a zip file
  static Future<List<Note>> importFromZip(
    List<int> zipBytes,
    StorageService storage,
  ) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final importedNotes = <Note>[];

    for (var file in archive) {
      if (file.isFile && file.name.endsWith('.md')) {
        final content = String.fromCharCodes(file.content as List<int>);
        final title = file.name
            .replaceFirst('notes/', '')
            .replaceAll('.md', '');
        
        final note = await storage.createNote(
          title: title,
          content: content,
          type: NoteType.markdown,
        );
        
        importedNotes.add(note);
      }
    }

    return importedNotes;
  }

  /// Imports a single markdown file
  static Future<Note> importMarkdown(
    List<int> fileBytes,
    String fileName,
    StorageService storage,
  ) async {
    final content = String.fromCharCodes(fileBytes);
    final title = fileName.replaceAll('.md', '');
    
    return await storage.createNote(
      title: title,
      content: content,
      type: NoteType.markdown,
    );
  }

  /// Imports a chat JSON file
  static Future<Note> importChatJson(
    List<int> fileBytes,
    String fileName,
    StorageService storage,
  ) async {
    final content = String.fromCharCodes(fileBytes);
    
    final note = await storage.createNote(
      title: fileName.replaceAll('.json', ''),
      content: content,
      type: NoteType.chat,
    );
    
    return note;
  }

  /// Imports a Gemini export file
  static Future<Note> importGeminiExport(
    List<int> fileBytes,
    String fileName,
    StorageService storage,
  ) async {
    final content = String.fromCharCodes(fileBytes);
    
    final note = await storage.createNote(
      title: fileName.replaceAll('.json', ''),
      content: content,
      type: NoteType.googleDocs,
    );
    
    return note;
  }
}
