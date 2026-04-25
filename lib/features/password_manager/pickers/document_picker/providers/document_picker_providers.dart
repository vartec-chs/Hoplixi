import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/models/document_picker_models.dart';
import 'package:hoplixi/main_db/core/dao/index.dart';
import 'package:hoplixi/main_db/core/models/filter/base_filter.dart';
import 'package:hoplixi/main_db/core/models/filter/documents_filter.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';

const int _pageSize = 20;

/// Provider для фильтра документов
final documentPickerFilterProvider =
    NotifierProvider<DocumentPickerFilterNotifier, DocumentsFilter>(
      DocumentPickerFilterNotifier.new,
    );

/// Управляет фильтром поиска в пикере документов
class DocumentPickerFilterNotifier extends Notifier<DocumentsFilter> {
  @override
  DocumentsFilter build() => _defaultFilter();

  DocumentsFilter _defaultFilter() => DocumentsFilter.create(
    base: BaseFilter.create(
      query: '',
      limit: _pageSize,
      offset: 0,
      sortDirection: SortDirection.desc,
    ),
    sortField: DocumentsSortField.modifiedAt,
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

/// Provider для загруженных данных документов
final documentPickerDataProvider =
    NotifierProvider<DocumentPickerDataNotifier, DocumentPickerData>(
      DocumentPickerDataNotifier.new,
    );

/// Управляет загруженными документами в пикере
class DocumentPickerDataNotifier extends Notifier<DocumentPickerData> {
  @override
  DocumentPickerData build() => const DocumentPickerData();

  /// Загрузить первую страницу документов
  Future<void> loadInitial(String? excludeDocumentId) async {
    final filter = ref.read(documentPickerFilterProvider);
    final dao = await _getDao();
    if (dao == null) return;

    try {
      final documents = await dao.getFiltered(filter);
      final total = await dao.countFiltered(filter);

      final filtered = excludeDocumentId != null
          ? documents.where((d) => d.id != excludeDocumentId).toList()
          : documents;

      state = DocumentPickerData(
        documents: filtered,
        hasMore: filtered.length < total,
        isLoadingMore: false,
        excludeDocumentId: excludeDocumentId,
      );
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }

  /// Загрузить следующую страницу документов
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final dao = await _getDao();
    if (dao == null) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      ref.read(documentPickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(documentPickerFilterProvider);

      final newDocuments = await dao.getFiltered(updatedFilter);
      final total = await dao.countFiltered(updatedFilter);

      final filteredNew = state.excludeDocumentId != null
          ? newDocuments.where((d) => d.id != state.excludeDocumentId).toList()
          : newDocuments;

      final allDocuments = [...state.documents, ...filteredNew];

      state = DocumentPickerData(
        documents: allDocuments,
        hasMore: allDocuments.length < total,
        isLoadingMore: false,
        excludeDocumentId: state.excludeDocumentId,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }

  Future<DocumentFilterDao?> _getDao() async {
    try {
      return await ref.read(documentFilterDaoProvider.future);
    } catch (_) {
      Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
      return null;
    }
  }
}
