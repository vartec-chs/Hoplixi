import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';

part 'drawer_filter_selection_storage.freezed.dart';

/// Хранит выбранные категории и теги для конкретной сущности
@freezed
sealed class DrawerFilterSelection with _$DrawerFilterSelection {
  const factory DrawerFilterSelection({
    @Default(<String>[]) List<String> selectedCategoryIds,
    @Default(<String>[]) List<String> selectedTagIds,
  }) = _DrawerFilterSelection;
}

/// Провайдер для хранения выборов фильтров для каждой сущности
final drawerFilterSelectionStorageProvider =
    NotifierProvider<
      DrawerFilterSelectionStorage,
      Map<EntityType, DrawerFilterSelection>
    >(DrawerFilterSelectionStorage.new);

class DrawerFilterSelectionStorage
    extends Notifier<Map<EntityType, DrawerFilterSelection>> {
  @override
  Map<EntityType, DrawerFilterSelection> build() {
    return {};
  }

  /// Получить выбор для конкретной сущности
  DrawerFilterSelection getSelection(EntityType entityType) {
    return state[entityType] ?? const DrawerFilterSelection();
  }

  /// Сохранить выбранные категории для сущности
  void setCategoryIds(EntityType entityType, List<String> categoryIds) {
    final current = getSelection(entityType);
    state = {
      ...state,
      entityType: current.copyWith(selectedCategoryIds: categoryIds),
    };
  }

  /// Сохранить выбранные теги для сущности
  void setTagIds(EntityType entityType, List<String> tagIds) {
    final current = getSelection(entityType);
    state = {...state, entityType: current.copyWith(selectedTagIds: tagIds)};
  }

  /// Сохранить полный выбор для сущности
  void setSelection(EntityType entityType, DrawerFilterSelection selection) {
    state = {...state, entityType: selection};
  }

  /// Очистить выбор для сущности
  void clearSelection(EntityType entityType) {
    state = {...state, entityType: const DrawerFilterSelection()};
  }
}
