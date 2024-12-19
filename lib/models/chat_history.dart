class ChatHistory {
  final String id;
  final DateTime timestamp;
  final String apiDocs;
  final List<ChatMessage> messages;

  ChatHistory({
    required this.id,
    required this.timestamp,
    required this.apiDocs,
    required this.messages,
  });
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
