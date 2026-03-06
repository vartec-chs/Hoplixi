import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Тип элемента истории обмена.
enum HistoryItemType { fileSent, fileReceived, textSent, textReceived }

/// Один элемент истории обмена внутри сессии.
class HistoryItem {
  HistoryItem({
    required this.type,
    required this.content,
    required this.timestamp,
    this.filePath,
  });

  /// Тип: файл/текст, отправлен/получен.
  final HistoryItemType type;

  /// Имя файла или текст сообщения.
  final String content;

  /// Время события.
  final DateTime timestamp;

  /// Путь к файлу на диске (для полученных и отправленных файлов).
  final String? filePath;

  bool get isSent =>
      type == HistoryItemType.fileSent || type == HistoryItemType.textSent;

  bool get isFile =>
      type == HistoryItemType.fileSent || type == HistoryItemType.fileReceived;
}

/// Провайдер истории обмена для текущей сессии.
final sessionHistoryProvider =
    NotifierProvider<SessionHistoryNotifier, List<HistoryItem>>(
      SessionHistoryNotifier.new,
    );

class SessionHistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() => [];

  /// Добавляет элемент в историю.
  void add(HistoryItemType type, String content, {String? filePath}) {
    state = [
      ...state,
      HistoryItem(
        type: type,
        content: content,
        timestamp: DateTime.now(),
        filePath: filePath,
      ),
    ];
  }

  /// Очищает историю (при отключении).
  void clear() {
    state = [];
  }
}
