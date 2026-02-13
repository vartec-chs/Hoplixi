import 'dart:convert';
import 'package:hoplixi/core/logger/models.dart';

/// Класс для парсинга записей JSONL логов
class LogParser {
  /// Парсит одну строку JSONL в LogEntry или SessionEvent
  static dynamic parseLine(String line) {
    try {
      final json = jsonDecode(line);

      // Проверяем тип события
      if (json['type'] == 'session_start' || json['type'] == 'session_end') {
        return SessionEvent.fromJson(json);
      }

      // Если нет типа, это обычный LogEntry
      if (json.containsKey('sessionId') && json.containsKey('level')) {
        return LogEntry(
          sessionId: json['sessionId'] ?? '',
          processId: json['processId'] ?? 0,
          timestamp: DateTime.parse(
            json['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
          level: _parseLogLevel(json['level']),
          message: json['message'] ?? '',
          tag: json['tag'],
          error: json['error'],
          stackTrace: json['stackTrace'] != null
              ? StackTrace.fromString(json['stackTrace'])
              : null,
          additionalData: json['additionalData'] is Map
              ? Map<String, dynamic>.from(json['additionalData'])
              : null,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Парсит весь JSONL файл в список записей
  static List<dynamic> parseJsonl(String content) {
    final lines = content.split('\n').where((line) => line.isNotEmpty).toList();
    return lines
        .map((line) => parseLine(line))
        .where((entry) => entry != null)
        .toList();
  }

  static LogLevel _parseLogLevel(String? levelStr) {
    switch (levelStr?.toUpperCase()) {
      case 'DEBUG':
        return LogLevel.debug;
      case 'INFO':
        return LogLevel.info;
      case 'WARNING':
        return LogLevel.warning;
      case 'ERROR':
        return LogLevel.error;
      case 'TRACE':
        return LogLevel.trace;
      case 'FATAL':
        return LogLevel.fatal;
      default:
        return LogLevel.info;
    }
  }
}

/// Класс для событий сессии
class SessionEvent {
  final String type; // 'session_start' или 'session_end'
  final DateTime timestamp;
  final Session session;

  SessionEvent({
    required this.type,
    required this.timestamp,
    required this.session,
  });

  factory SessionEvent.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['session'] ?? {};
    final deviceInfoJson = sessionJson['deviceInfo'] ?? {};

    final deviceInfo = DeviceInfo(
      deviceId: deviceInfoJson['deviceId'] ?? '',
      platform: deviceInfoJson['platform'] ?? '',
      platformVersion: deviceInfoJson['platformVersion'] ?? '',
      deviceModel: deviceInfoJson['deviceModel'] ?? '',
      deviceManufacturer: deviceInfoJson['deviceManufacturer'] ?? '',
      appName: deviceInfoJson['appName'] ?? '',
      appVersion: deviceInfoJson['appVersion'] ?? '',
      buildNumber: deviceInfoJson['buildNumber'] ?? '',
      packageName: deviceInfoJson['packageName'] ?? '',
      additionalInfo: deviceInfoJson['additionalInfo'] is Map
          ? Map<String, dynamic>.from(deviceInfoJson['additionalInfo'])
          : {},
    );

    final session = Session(
      id: sessionJson['id'] ?? '',
      startTime: DateTime.parse(
        sessionJson['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      deviceInfo: deviceInfo,
      isSubWindow: sessionJson['isSubWindow'] ?? false,
      windowType: sessionJson['windowType'],
      endTime: sessionJson['endTime'] != null
          ? DateTime.parse(sessionJson['endTime'])
          : null,
    );

    return SessionEvent(
      type: json['type'] ?? 'unknown',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      session: session,
    );
  }
}
