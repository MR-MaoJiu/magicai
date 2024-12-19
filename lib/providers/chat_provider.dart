import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? apiDocs;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.apiDocs,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'api_docs': apiDocs,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        content: json['content'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        apiDocs: json['api_docs'],
      );
}

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

class ChatProvider with ChangeNotifier {
  List<ChatHistory> _history = [];
  List<ChatMessage> _messages = [];

  List<ChatHistory> get history => _history;
  List<ChatMessage> get messages => _messages;

  Future<void> loadHistoryMessages(String historyId) async {
    final history = _history.firstWhere((h) => h.id == historyId);
    _messages = history.messages;
    notifyListeners();
  }

  Future<void> addMessage(String content, bool isUser,
      {String? apiDocs}) async {
    final message = ChatMessage(
      content: content,
      isUser: isUser,
      timestamp: DateTime.now(),
      apiDocs: apiDocs,
    );

    _messages.add(message);
    if (!isUser) {
      // 只在AI回复时添加到历史记录
      _history.add(ChatHistory(
        id: DateTime.now().toIso8601String(),
        timestamp: DateTime.now(),
        apiDocs: apiDocs ?? '',
        messages: [message],
      ));
    }
    notifyListeners();

    await _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history
        .map((h) => {
              'id': h.id,
              'timestamp': h.timestamp.toIso8601String(),
              'api_docs': h.apiDocs,
              'messages': h.messages.map((m) => m.toJson()).toList(),
            })
        .toList();
    await prefs.setString('chat_history', json.encode(historyJson));
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('chat_history');

    if (historyString != null) {
      final historyJson = json.decode(historyString) as List;
      _history = List<ChatHistory>.from(historyJson.map((h) => ChatHistory(
            id: h['id'],
            timestamp: DateTime.parse(h['timestamp']),
            apiDocs: h['api_docs'],
            messages: List<ChatMessage>.from(
                h['messages'].map((m) => ChatMessage.fromJson(m)).toList()),
          )));
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _messages.clear();
    _history.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
  }
}
