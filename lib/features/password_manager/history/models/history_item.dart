import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';

part 'history_item.freezed.dart';

/// Унифицированный элемент истории для всех типов сущностей
@freezed
sealed class HistoryItem with _$HistoryItem {
  const HistoryItem._();

  const factory HistoryItem({
    /// ID записи в истории
    required String id,

    /// ID оригинальной сущности
    required String originalEntityId,

    /// Тип сущности
    required EntityType entityType,

    /// Действие (deleted, modified)
    required String action,

    /// Название/заголовок записи
    required String title,

    /// Дополнительная информация (логин, описание и т.д.)
    String? subtitle,

    /// Дата действия
    required DateTime actionAt,
  }) = _HistoryItem;

  /// Проверяет, является ли действие удалением
  bool get isDeleted => action == 'deleted';

  /// Проверяет, является ли действие модификацией
  bool get isModified => action == 'modified';

  /// Локализованное название действия
  String get actionLabel {
    switch (action) {
      case 'deleted':
        return 'Удалено';
      case 'modified':
        return 'Изменено';
      default:
        return action;
    }
  }
}
