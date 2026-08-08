import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final int index;
  final String userMessage;
  final String thoughts;
  final String modelResponse;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.index,
    required this.userMessage,
    this.thoughts = '',
    required this.modelResponse,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'user': userMessage,
      'thoughts': thoughts,
      'model': modelResponse,
      'time': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(String key, Map<String, dynamic> map) {
    return ChatMessage(
      index: int.tryParse(key) ?? 0,
      userMessage: map['user'] ?? '',
      thoughts: map['thoughts'] ?? '',
      modelResponse: map['model'] ?? '',
      timestamp: map['time'] != null ? DateTime.parse(map['time']) : null,
    );
  }

  static List<ChatMessage> fromJsonMap(Map<String, dynamic> json) {
    final messages = <ChatMessage>[];
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        messages.add(ChatMessage.fromMap(key, value));
      }
    });
    messages.sort((a, b) => a.index.compareTo(b.index));
    return messages;
  }

  static Map<String, dynamic> toJsonMap(List<ChatMessage> messages) {
    final json = <String, dynamic>{};
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      json['${i + 1}'] = {
        'user': msg.userMessage,
        'thoughts': msg.thoughts,
        'model': msg.modelResponse,
        'time': msg.timestamp.toIso8601String(),
      };
    }
    return json;
  }
}
