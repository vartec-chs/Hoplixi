import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/document_picker/models/document_picker_models.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:result_dart/result_dart.dart';

const int _pageSize = 20;

/// Provider для фильтра документов
final documentPickerFilterProvider =
    NotifierProvider<DocumentPickerFilterNotifier, DocumentFilter>(
      DocumentPickerFilterNotifier.new,
    );

/// Управляет фильтром поиска в пикере документов
class DocumentPickerFilterNotifier extends Notifier<DocumentFilter> {
  @override
  DocumentFilter build() => _defaultFilter();

  DocumentFilter _defaultFilter() => DocumentFilter.create(
    base: BaseFilter.create(
      query: '',
      limit: _pageSize,
      offset: 0,
      sortDirection: SortDirection.desc,
    ),
    sortField: DocumentSortField.modifiedAt,
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
    final service = await _getService();
    if (service == null) return;

    try {
      final documents = (await service.getDocuments(filter)).getOrThrow();
      final total = (await service.countDocuments(filter)).getOrThrow();

      final filtered = excludeDocumentId != null
          ? documents
                .where((d) => d.card.item.itemId != excludeDocumentId)
                .toList()
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

    final service = await _getService();
    if (service == null) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      ref.read(documentPickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(documentPickerFilterProvider);

      final newDocuments = (await service.getDocuments(
        updatedFilter,
      )).getOrThrow();
      final total = (await service.countDocuments(updatedFilter)).getOrThrow();

      final filteredNew = state.excludeDocumentId != null
          ? newDocuments
                .where((d) => d.card.item.itemId != state.excludeDocumentId)
                .toList()
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

  Future<VaultCardFilterService?> _getService() async {
    try {
      return await ref.read(vaultCardFilterServiceProvider.future);
    } catch (_) {
      Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
      return null;
    }
  }
}
