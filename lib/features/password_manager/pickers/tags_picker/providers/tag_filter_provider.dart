import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';

/// Провайдер для управления состоянием фильтра тегов
final tagPickerFilterProvider =
    NotifierProvider.autoDispose<TagFilterNotifier, TagsFilter>(() {
      return TagFilterNotifier();
    });

/// Notifier для управления фильтром тегов
class TagFilterNotifier extends Notifier<TagsFilter> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  TagsFilter build() {
    // Очищаем таймер при destroy провайдера
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const TagsFilter();
  }

  /// Обновить поисковый запрос с дебаунсингом
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      state = state.copyWith(query: query.trim());
    });
  }

  /// Обновить тип тега
  Future<void> updateType(List<TagType?> types) async {
    state = state.copyWith(types: types);
  }

  /// Обновить цвет
  Future<void> updateColor(String? color) async {
    state = state.copyWith(color: color);
  }

  /// Обновить дату создания (после)
  Future<void> updateCreatedAfter(DateTime? date) async {
    state = state.copyWith(createdAfter: date);
  }

  /// Обновить дату создания (до)
  Future<void> updateCreatedBefore(DateTime? date) async {
    state = state.copyWith(createdBefore: date);
  }

  /// Обновить дату изменения (после)
  Future<void> updateModifiedAfter(DateTime? date) async {
    state = state.copyWith(modifiedAfter: date);
  }

  /// Обновить дату изменения (до)
  Future<void> updateModifiedBefore(DateTime? date) async {
    state = state.copyWith(modifiedBefore: date);
  }

  /// Обновить поле сортировки
  Future<void> updateSortField(TagsSortField sortField) async {
    state = state.copyWith(sortField: sortField);
  }

  /// Сбросить фильтр к начальному состоянию
  Future<void> reset() async {
    _debounceTimer?.cancel();
    state = const TagsFilter();
  }

  /// Обновить весь фильтр сразу
  Future<void> updateFilter(TagsFilter filter) async {
    _debounceTimer?.cancel();
    state = filter;
  }
}
