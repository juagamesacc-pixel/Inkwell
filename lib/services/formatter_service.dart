import 'dart:convert';
import '../models/chat_message.dart';

class FormatterService {
  /// Converts Gemini/Google Docs export format to simplified chat JSON
  static Map<String, dynamic> convertGeminiToChat(Map<String, dynamic> geminiData) {
    final chunks = geminiData['chunkedPrompt']?['chunks'] as List? ?? [];
    final messages = <Map<String, dynamic>>[];
    int index = 1;

    for (var chunk in chunks) {
      final role = chunk['role'] as String?;
      if (role == null) continue;

      final text = chunk['text'] as String? ?? '';
      final createTime = chunk['createTime'] as String? ?? DateTime.now().toIso8601String();
      final isThought = chunk['isThought'] as bool? ?? false;
      
      // Extract thoughts from parts
      String thoughts = '';
      final parts = chunk['parts'] as List? ?? [];
      for (var part in parts) {
        if (part['thought'] == true) {
          thoughts += part['text'] as String? ?? '';
        }
      }

      if (role == 'user' && text.isNotEmpty) {
        // Look for next model response
        String modelResponse = '';
        String modelTime = createTime;
        
        // Find the next model chunk
        for (var nextChunk in chunks) {
          if (nextChunk['role'] == 'model' && nextChunk['finishReason'] == 'STOP') {
            final nextParts = nextChunk['parts'] as List? ?? [];
            final mainText = nextParts
                .where((p) => p['thought'] != true && (p['text'] as String?)?.isNotEmpty == true)
                .map((p) => p['text'] as String)
                .join();
            
            if (mainText.isNotEmpty) {
              modelResponse = mainText;
              modelTime = nextChunk['createTime'] as String? ?? modelTime;
              break;
            }
          }
        }

        messages.add({
          'index': index,
          'user': text,
          'thoughts': thoughts,
          'model': modelResponse,
          'time': modelTime,
        });
        index++;
      }
    }

    return Map.fromEntries(
      messages.asMap().entries.map((e) => MapEntry('${e.key + 1}', e.value)),
    );
  }

  /// Converts simplified chat JSON to list of ChatMessage
  static List<ChatMessage> parseChatJson(Map<String, dynamic> json) {
    return ChatMessage.fromJsonMap(json);
  }

  /// Converts list of ChatMessage to simplified chat JSON
  static Map<String, dynamic> chatToJson(List<ChatMessage> messages) {
    return ChatMessage.toJsonMap(messages);
  }

  /// Validates if a JSON is in the required chat format
  static bool isValidChatFormat(Map<String, dynamic> json) {
    if (json.isEmpty) return false;
    
    for (var entry in json.entries) {
      if (entry.value is! Map<String, dynamic>) return false;
      final map = entry.value as Map<String, dynamic>;
      if (!map.containsKey('user') || !map.containsKey('model')) return false;
    }
    return true;
  }

  /// Validates if a JSON is in Gemini export format
  static bool isGeminiFormat(Map<String, dynamic> json) {
    return json.containsKey('chunkedPrompt') && 
           json['chunkedPrompt'] is Map &&
           (json['chunkedPrompt'] as Map).containsKey('chunks');
  }

  /// Pretty print JSON
  static String prettyJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
