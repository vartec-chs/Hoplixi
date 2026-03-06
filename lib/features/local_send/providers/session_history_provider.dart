import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/services/local_send_history_service.dart';

/// Провайдер истории обмена для текущей сессии.
final sessionHistoryProvider =
    NotifierProvider.autoDispose<SessionHistoryNotifier, List<HistoryItem>>(
      SessionHistoryNotifier.new,
    );

class SessionHistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() {
    return [];
  }

  Future<void> _saveHistory() async {
    final service = ref.read(localSendHistoryServiceProvider);
    await service.saveHistory(state);
  }

  /// Добавляет элемент в историю и сохраняет.
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
    _saveHistory();
  }

  /// Очищает историю и удаляет файл.
  void clear() {
    state = [];
  }
}
