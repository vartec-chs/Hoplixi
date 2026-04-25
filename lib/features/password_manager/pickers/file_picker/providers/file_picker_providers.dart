import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/file_picker/models/file_picker_models.dart';
import 'package:hoplixi/main_db/core/dao/index.dart';
import 'package:hoplixi/main_db/core/models/filter/base_filter.dart';
import 'package:hoplixi/main_db/core/models/filter/files_filter.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';

const int _pageSize = 20;

/// Provider для фильтра файлов
final filePickerFilterProvider =
    NotifierProvider<FilePickerFilterNotifier, FilesFilter>(
      FilePickerFilterNotifier.new,
    );

/// Управляет фильтром поиска в пикере файлов
class FilePickerFilterNotifier extends Notifier<FilesFilter> {
  @override
  FilesFilter build() => _defaultFilter();

  FilesFilter _defaultFilter() => FilesFilter.create(
    base: BaseFilter.create(
      query: '',
      limit: _pageSize,
      offset: 0,
      sortDirection: SortDirection.desc,
    ),
    sortField: FilesSortField.modifiedAt,
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
      base: state.base.copyWith(offset: (state.base.offset ?? 0) + _pageSize),
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
    final dao = await _getDao();
    if (dao == null) return;

    try {
      final files = await dao.getFiltered(filter);
      final total = await dao.countFiltered(filter);

      final filtered = excludeFileId != null
          ? files.where((f) => f.id != excludeFileId).toList()
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

    final dao = await _getDao();
    if (dao == null) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      ref.read(filePickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(filePickerFilterProvider);

      final newFiles = await dao.getFiltered(updatedFilter);
      final total = await dao.countFiltered(updatedFilter);

      final filteredNew = state.excludeFileId != null
          ? newFiles.where((f) => f.id != state.excludeFileId).toList()
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

  Future<FileFilterDao?> _getDao() async {
    try {
      return await ref.read(fileFilterDaoProvider.future);
    } catch (_) {
      Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
      return null;
    }
  }
}
