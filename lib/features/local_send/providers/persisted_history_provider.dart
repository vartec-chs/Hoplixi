import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/services/local_send_history_service.dart';

/// Провайдер для управления персистентной историей обменов.
final persistedHistoryProvider =
    AsyncNotifierProvider.autoDispose<PersistedHistoryNotifier, List<HistoryItem>>(
      PersistedHistoryNotifier.new,
    );

class PersistedHistoryNotifier extends AsyncNotifier<List<HistoryItem>> {
  @override
  Future<List<HistoryItem>> build() async {
    final service = ref.read(localSendHistoryServiceProvider);
    return service.loadHistory();
  }

  /// Удаляет один элемент истории по индексу и сохраняет.
  Future<void> removeAt(int index) async {
    final current = state.value ?? [];
    if (index < 0 || index >= current.length) return;
    final updated = List<HistoryItem>.from(current)..removeAt(index);
    state = AsyncData(updated);
    await ref.read(localSendHistoryServiceProvider).saveHistory(updated);
  }

  /// Очищает всю историю.
  Future<void> clearAll() async {
    state = const AsyncData([]);
    await ref.read(localSendHistoryServiceProvider).clearHistory();
  }

  /// Перезагружает историю с диска.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(localSendHistoryServiceProvider).loadHistory(),
    );
  }
}
