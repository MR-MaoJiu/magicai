import 'package:flutter/foundation.dart';

enum LogLevel {
  info,
  warning,
  error,
}

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

class LogService extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  double _progress = 0.0;
  String _currentStep = '';

  double get progress => _progress;
  String get currentStep => _currentStep;

  void log(String message, {LogLevel level = LogLevel.info}) {
    _logs.add(LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // 同时在调试控制台输出
    if (kDebugMode) {
      print('${level.name.toUpperCase()}: $message');
    }
  }

  void updateProgress(double value, String step) {
    _progress = value;
    _currentStep = step;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
