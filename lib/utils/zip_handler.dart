import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../models/note.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';

class ZipHandler {
  /// Exports multiple notes to a zip file.
  static Future<File> exportNotesToZip(
    List<Note> notes,
    StorageService storage,
  ) async {
    final archive = Archive();

    for (var note in notes) {
      final content = await storage.readNoteContent(note);
      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}.md';

      archive.addFile(ArchiveFile(
        'notes/$fileName',
        utf8.encode(content).length,
        utf8.encode(content),
      ));

      final metadata = jsonEncode(note.toMap());
      archive.addFile(ArchiveFile(
        'metadata/${note.id}.json',
        utf8.encode(metadata).length,
        utf8.encode(metadata),
      ));
    }

    final zipData = ZipEncoder().encode(archive);
    final dir = storage.exportsDirectory;
    final file = File('${dir!.path}/inkwell_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    await file.writeAsBytes(zipData ?? []);
    return file;
  }

  /// Imports notes from a zip file.
  static Future<List<Note>> importFromZip(
    List<int> zipBytes,
    StorageService storage,
  ) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final importedNotes = <Note>[];

    for (var file in archive) {
      if (file.isFile && file.name.endsWith('.md')) {
        final content = utf8.decode(file.content as List<int>, allowMalformed: true);
        final title = file.name
            .replaceFirst(RegExp(r'^notes?/'), '')
            .replaceAll(RegExp(r'\.md$'), '')
            .trim();
        final note = await storage.createNote(
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
          type: NoteType.markdown,
        );
        importedNotes.add(note);
      }
    }

    return importedNotes;
  }
}
