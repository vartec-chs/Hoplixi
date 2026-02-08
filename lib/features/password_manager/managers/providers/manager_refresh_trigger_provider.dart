import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Тип ресурса для обновления
enum ManagerResourceType { category, tag, icon }

/// Состояние триггера обновления
class ManagerRefreshState {
  final ManagerResourceType? resourceType;
  final DateTime timestamp;

  const ManagerRefreshState({this.resourceType, required this.timestamp});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagerRefreshState &&
          runtimeType == other.runtimeType &&
          resourceType == other.resourceType &&
          timestamp == other.timestamp;

  @override
  int get hashCode => resourceType.hashCode ^ timestamp.hashCode;
}

/// Провайдер для триггера обновления списков менеджеров
final managerRefreshTriggerProvider =
    NotifierProvider<ManagerRefreshTriggerNotifier, ManagerRefreshState>(
      () => ManagerRefreshTriggerNotifier(),
    );

/// Notifier для управления триггерами обновления
class ManagerRefreshTriggerNotifier extends Notifier<ManagerRefreshState> {
  @override
  ManagerRefreshState build() {
    return ManagerRefreshState(timestamp: DateTime.now());
  }

  /// Триггерит обновление категорий
  void triggerCategoryRefresh() {
    state = ManagerRefreshState(
      resourceType: ManagerResourceType.category,
      timestamp: DateTime.now(),
    );
  }

  /// Триггерит обновление тегов
  void triggerTagRefresh() {
    state = ManagerRefreshState(
      resourceType: ManagerResourceType.tag,
      timestamp: DateTime.now(),
    );
  }

  /// Триггерит обновление иконок
  void triggerIconRefresh() {
    state = ManagerRefreshState(
      resourceType: ManagerResourceType.icon,
      timestamp: DateTime.now(),
    );
  }

  /// Универсальный метод для обновления по типу
  void triggerRefresh(ManagerResourceType resourceType) {
    state = ManagerRefreshState(
      resourceType: resourceType,
      timestamp: DateTime.now(),
    );
  }

  /// Триггерит обновление всех ресурсов
  void triggerRefreshAll() {
    state = ManagerRefreshState(resourceType: null, timestamp: DateTime.now());
  }
}
