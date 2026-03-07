import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/base_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/models/drawer_tag_filter_state.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

const int _kTagPageSize = 20;
const Duration _kTagSearchDebounce = Duration(milliseconds: 300);

/// Провайдер для загрузки и фильтрации тегов в drawer
/// Family по EntityType — отдельный экземпляр для каждого типа сущности
final drawerTagFilterProvider =
    AsyncNotifierProvider.family<
      DrawerTagFilterNotifier,
      DrawerTagFilterState,
      EntityType
    >(DrawerTagFilterNotifier.new);

class DrawerTagFilterNotifier extends AsyncNotifier<DrawerTagFilterState> {
  static const String _logTag = 'DrawerTagFilterNotifier';
  Timer? _searchDebounce;

  DrawerTagFilterNotifier(this._entityType);

  final EntityType _entityType;

  @override
  Future<DrawerTagFilterState> build() async {
    ref.onDispose(() => _searchDebounce?.cancel());

    ref.listen<ManagerRefreshState>(managerRefreshTriggerProvider, (
      previous,
      next,
    ) {
      if (next.resourceType == ManagerResourceType.tag) {
        logDebug(
          '$_logTag Обнаружено изменение тегов, перезагружаем...',
          tag: _logTag,
        );
        _reload();
      }
    });

    try {
      final tagDao = await ref.read(tagDaoProvider.future);
      final filter = TagsFilter.create(
        query: '',
        types: [_entityType.toTagType(), TagType.mixed],
        limit: _kTagPageSize,
        offset: 0,
      );
      final tags = await tagDao.getTagCardsFiltered(filter);
      return DrawerTagFilterState(
        tags: tags,
        offset: _kTagPageSize,
        hasMore: tags.length >= _kTagPageSize,
      );
    } catch (e, s) {
      logError(
        '$_logTag Ошибка загрузки начальных данных',
        error: e,
        stackTrace: s,
      );
      return const DrawerTagFilterState();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Загрузка данных
  // ─────────────────────────────────────────────────────────────────────────

  void _reload() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(searchQuery: '', offset: 0));
      _load(reset: true);
    });
  }

  void reload() => _reload();

  Future<void> _load({bool reset = false}) async {
    final s = state.value;
    if (s == null || s.isLoading) return;

    state = AsyncValue.data(s.copyWith(isLoading: true));

    try {
      final tagDao = await ref.read(tagDaoProvider.future);
      final offset = reset ? 0 : s.offset;
      final filter = TagsFilter.create(
        query: s.searchQuery,
        types: [_entityType.toTagType(), TagType.mixed],
        limit: _kTagPageSize,
        offset: offset,
      );
      final tags = await tagDao.getTagCardsFiltered(filter);

      logDebug('$_logTag Загружено тегов: ${tags.length}, reset: $reset');

      if (reset) {
        state = AsyncValue.data(
          s.copyWith(
            tags: tags,
            offset: _kTagPageSize,
            hasMore: tags.length >= _kTagPageSize,
            isLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          s.copyWith(
            tags: [...s.tags, ...tags],
            offset: offset + _kTagPageSize,
            hasMore: tags.length >= _kTagPageSize,
            isLoading: false,
          ),
        );
      }
    } catch (e, st) {
      logError('$_logTag Ошибка загрузки тегов', error: e, stackTrace: st);
      state = AsyncValue.data(s.copyWith(isLoading: false));
    }
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || !s.hasMore || s.isLoading) return;
    await _load(reset: false);
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_kTagSearchDebounce, () {
      state.whenData((s) {
        state = AsyncValue.data(s.copyWith(searchQuery: query));
        _load(reset: true);
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Выбор тегов
  // ─────────────────────────────────────────────────────────────────────────

  void toggle(String id) {
    state.whenData((s) {
      final selected = s.selectedIds;
      final updated = selected.contains(id)
          ? selected.where((e) => e != id).toList()
          : [...selected, id];
      state = AsyncValue.data(s.copyWith(selectedIds: updated));
      _applyToBase();
    });
  }

  void clearSelection() {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(selectedIds: []));
      _applyToBase();
    });
  }

  void _applyToBase() {
    state.whenData((s) {
      ref.read(baseFilterProvider.notifier).setTagIds(s.selectedIds);
    });
  }
}
