import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/filter_providers.dart';
import 'package:hoplixi/features/password_manager/dashboard_layout/dashboard_drawer/models/drawer_tag_filter_state.dart';
import 'package:hoplixi/features/password_manager/managers/providers/manager_refresh_trigger_provider.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/tag_dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

const int _kTagPageSize = 20;
const Duration _kTagSearchDebounce = Duration(milliseconds: 300);

final drawerTagFilterProvider = AsyncNotifierProvider.autoDispose
    .family<DrawerTagFilterNotifier, DrawerTagFilterState, EntityType>(
      DrawerTagFilterNotifier.new,
    );

class DrawerTagFilterNotifier extends AsyncNotifier<DrawerTagFilterState> {
  static const String _logTag = 'DrawerTagFilterNotifier';
  Timer? _searchDebounce;
  List<TagCardDto> _allTags = const [];

  DrawerTagFilterNotifier(EntityType _);

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
      await _refreshCache();
      final tags = _sliceTags(offset: 0, query: '');
      return DrawerTagFilterState(
        tags: tags,
        offset: tags.length,
        hasMore: tags.length < _filteredTags('').length,
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

  Future<void> _refreshCache() async {
    final repositories = await ref.read(vaultRepositories.future);
    final tags = (await repositories.tag.getAllTags()).getOrThrow()
      ..sort((a, b) => a.name.compareTo(b.name));
    _allTags = tags;
  }

  List<TagCardDto> _filteredTags(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _allTags;
    return _allTags
        .where((tag) => tag.name.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  List<TagCardDto> _sliceTags({required int offset, required String query}) {
    final tags = _filteredTags(query);
    final end = (offset + _kTagPageSize).clamp(0, tags.length);
    if (offset >= end) return const [];
    return tags.sublist(offset, end);
  }

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
      if (reset) await _refreshCache();

      final offset = reset ? 0 : s.offset;
      final tags = _sliceTags(offset: offset, query: s.searchQuery);
      final total = _filteredTags(s.searchQuery).length;

      logDebug('$_logTag Загружено тегов: ${tags.length}, reset: $reset');

      if (reset) {
        state = AsyncValue.data(
          s.copyWith(
            tags: tags,
            offset: tags.length,
            hasMore: tags.length < total,
            isLoading: false,
          ),
        );
      } else {
        state = AsyncValue.data(
          s.copyWith(
            tags: [...s.tags, ...tags],
            offset: offset + tags.length,
            hasMore: offset + tags.length < total,
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
        state = AsyncValue.data(
          s.copyWith(searchQuery: query.trim(), offset: 0),
        );
        _load(reset: true);
      });
    });
  }

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
