import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/models/file_picker_models.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:result_dart/result_dart.dart';

const int _pageSize = 20;

/// Provider для фильтра файлов
final filePickerFilterProvider =
    NotifierProvider<FilePickerFilterNotifier, FileFilter>(
      FilePickerFilterNotifier.new,
    );

/// Управляет фильтром поиска в пикере файлов
class FilePickerFilterNotifier extends Notifier<FileFilter> {
  @override
  FileFilter build() => _defaultFilter();

  FileFilter _defaultFilter() => FileFilter.create(
    base: BaseFilter.create(
      query: '',
      limit: _pageSize,
      offset: 0,
      sortDirection: SortDirection.desc,
    ),
    sortField: FileSortField.modifiedAt,
  );

  /// Обновить поисковый запрос и сбросить offset
  void updateQuery(String query) {
    state = state.copyWith(
      base: state.base.copyWith(query: query.trim(), offset: 0),
    );
  }

  /// Увеличить offset для пагинации
  void incrementOffset() {
    state = state.copyWith(
      base: state.base.copyWith(offset: state.base.offset + _pageSize),
    );
  }

  /// Сбросить фильтр к начальному состоянию
  void reset() {
    state = _defaultFilter();
  }
}

/// Provider для загруженных данных файлов
final filePickerDataProvider =
    NotifierProvider<FilePickerDataNotifier, FilePickerData>(
      FilePickerDataNotifier.new,
    );

/// Управляет загруженными файлами в пикере
class FilePickerDataNotifier extends Notifier<FilePickerData> {
  @override
  FilePickerData build() => const FilePickerData();

  /// Загрузить первую страницу файлов
  Future<void> loadInitial(String? excludeFileId) async {
    final filter = ref.read(filePickerFilterProvider);
    final service = await _getService();
    if (service == null) return;

    try {
      final files = (await service.getFiles(filter)).getOrThrow();
      final total = (await service.countFiles(filter)).getOrThrow();

      final filtered = excludeFileId != null
          ? files.where((f) => f.card.item.itemId != excludeFileId).toList()
          : files;

      state = FilePickerData(
        files: filtered,
        hasMore: filtered.length < total,
        isLoadingMore: false,
        excludeFileId: excludeFileId,
      );
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }

  /// Загрузить следующую страницу файлов
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final service = await _getService();
    if (service == null) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      ref.read(filePickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(filePickerFilterProvider);

      final newFiles = (await service.getFiles(updatedFilter)).getOrThrow();
      final total = (await service.countFiles(updatedFilter)).getOrThrow();

      final filteredNew = state.excludeFileId != null
          ? newFiles
                .where((f) => f.card.item.itemId != state.excludeFileId)
                .toList()
          : newFiles;

      final allFiles = [...state.files, ...filteredNew];

      state = FilePickerData(
        files: allFiles,
        hasMore: allFiles.length < total,
        isLoadingMore: false,
        excludeFileId: state.excludeFileId,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }

  Future<VaultCardFilterService?> _getService() async {
    try {
      return await ref.read(vaultCardFilterServiceProvider.future);
    } catch (_) {
      Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
      return null;
    }
  }
}
