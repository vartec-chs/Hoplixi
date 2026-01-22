import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/history/models/history_item.dart';
import 'package:hoplixi/features/password_manager/history/models/history_list_state.dart';
import 'package:hoplixi/features/password_manager/history/providers/history_search_provider.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

/// Константа размера страницы для пагинации истории
const int kHistoryPageSize = 20;

/// Параметры для провайдера истории
class HistoryParams {
  final EntityType entityType;
  final String entityId;

  const HistoryParams({required this.entityType, required this.entityId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryParams &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => entityType.hashCode ^ entityId.hashCode;
}

/// Провайдер параметров истории
/// Устанавливается перед использованием historyListProvider
final historyParamsProvider =
    NotifierProvider.autoDispose<HistoryParamsNotifier, HistoryParams?>(
      HistoryParamsNotifier.new,
    );

/// Нотификатор для управления параметрами истории
class HistoryParamsNotifier extends Notifier<HistoryParams?> {
  @override
  HistoryParams? build() => null;

  /// Установить параметры истории
  void setParams(HistoryParams params) {
    state = params;
  }

  /// Очистить параметры
  void clear() {
    state = null;
  }
}

/// Провайдер для управления списком истории с пагинацией
final historyListProvider =
    AsyncNotifierProvider.autoDispose<HistoryListNotifier, HistoryListState>(
      HistoryListNotifier.new,
    );

/// Нотификатор для управления списком истории
class HistoryListNotifier extends AsyncNotifier<HistoryListState> {
  static const String _logTag = 'HistoryListNotifier';

  HistoryParams get _params {
    final params = ref.read(historyParamsProvider);
    if (params == null) {
      throw StateError(
        'HistoryParams не установлены. '
        'Установите historyParamsProvider перед использованием historyListProvider.',
      );
    }
    return params;
  }

  int get pageSize => kHistoryPageSize;

  @override
  Future<HistoryListState> build() async {
    // Следим за изменениями параметров через watch
    // При изменении params провайдер автоматически пересоздастся
    final params = ref.watch(historyParamsProvider);
    if (params == null) {
      return const HistoryListState(
        items: [],
        isLoading: false,
        hasMore: false,
        totalCount: 0,
      );
    }

    // Следим за изменениями поиска через watch
    // При изменении query провайдер автоматически пересоздастся
    final searchState = ref.watch(historySearchProvider);

    return _loadInitialData(searchQuery: searchState.query);
  }

  /// Загрузить начальные данные
  Future<HistoryListState> _loadInitialData({String? searchQuery}) async {
    try {
      final items = await _fetchHistoryItems(page: 1, searchQuery: searchQuery);

      final totalCount = await _getTotalCount(searchQuery: searchQuery);

      return HistoryListState(
        items: items,
        isLoading: false,
        hasMore: items.length >= pageSize && items.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      );
    } catch (e, st) {
      logError(
        'Ошибка загрузки истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      return HistoryListState(error: e.toString());
    }
  }

  /// Загрузить следующую страницу
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    try {
      state = AsyncValue.data(current.copyWith(isLoadingMore: true));

      final nextPage = current.currentPage + 1;
      final searchState = ref.read(historySearchProvider);
      final newItems = await _fetchHistoryItems(
        page: nextPage,
        searchQuery: searchState.query,
      );

      final allItems = [...current.items, ...newItems];
      final hasMore =
          newItems.length >= pageSize && allItems.length < current.totalCount;

      state = AsyncValue.data(
        current.copyWith(
          items: allItems,
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: nextPage,
        ),
      );
    } catch (e, st) {
      logError(
        'Ошибка загрузки дополнительной истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  /// Обновить список истории
  Future<void> refresh() async {
    final current = state.value;
    final searchState = ref.read(historySearchProvider);

    if (current != null) {
      state = AsyncValue.data(current.copyWith(isLoading: true, error: null));
      try {
        final newState = await _loadInitialData(searchQuery: searchState.query);
        state = AsyncValue.data(newState);
      } catch (e) {
        state = AsyncValue.data(
          current.copyWith(isLoading: false, error: e.toString()),
        );
      }
    } else {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(
        () => _loadInitialData(searchQuery: searchState.query),
      );
    }
  }

  /// Удалить одну запись из истории
  Future<bool> deleteHistoryItem(String historyItemId) async {
    final current = state.value;
    if (current == null) return false;

    final index = current.items.indexWhere((e) => e.id == historyItemId);
    if (index == -1) return false;

    final item = current.items[index];
    final updated = [...current.items];
    updated.removeAt(index);

    // Оптимистичное обновление
    state = AsyncValue.data(
      current.copyWith(items: updated, totalCount: current.totalCount - 1),
    );

    try {
      final success = await _deleteHistoryItemFromDb(historyItemId);

      if (!success) {
        // Откат при неудаче
        updated.insert(index, item);
        state = AsyncValue.data(
          current.copyWith(items: updated, totalCount: current.totalCount),
        );
        return false;
      }

      logInfo('Запись истории удалена: $historyItemId', tag: _logTag);
      return true;
    } catch (e, st) {
      logError(
        'Ошибка удаления записи истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      // Откат при ошибке
      updated.insert(index, item);
      state = AsyncValue.data(
        current.copyWith(items: updated, totalCount: current.totalCount),
      );
      return false;
    }
  }

  /// Удалить всю историю для текущей сущности
  Future<bool> deleteAllHistory() async {
    final current = state.value;
    if (current == null) return false;

    // Оптимистичное обновление
    state = AsyncValue.data(
      const HistoryListState(
        items: [],
        isLoading: false,
        hasMore: false,
        totalCount: 0,
      ),
    );

    try {
      final success = await _deleteAllHistoryFromDb();

      if (!success) {
        // Откат при неудаче
        state = AsyncValue.data(current);
        return false;
      }

      logInfo(
        'Вся история удалена для: ${_params.entityType.label} (${_params.entityId})',
        tag: _logTag,
      );
      return true;
    } catch (e, st) {
      logError(
        'Ошибка удаления всей истории',
        tag: _logTag,
        error: e,
        stackTrace: st,
      );
      // Откат при ошибке
      state = AsyncValue.data(current);
      return false;
    }
  }

  // ============================================
  // Приватные методы для работы с DAO
  // ============================================

  /// Получить элементы истории с пагинацией
  Future<List<HistoryItem>> _fetchHistoryItems({
    required int page,
    String? searchQuery,
  }) async {
    final offset = (page - 1) * pageSize;

    switch (_params.entityType) {
      case EntityType.password:
        return _fetchPasswordHistory(offset, searchQuery);
      case EntityType.note:
        return _fetchNoteHistory(offset, searchQuery);
      case EntityType.bankCard:
        return _fetchBankCardHistory(offset, searchQuery);
      case EntityType.file:
        return _fetchFileHistory(offset, searchQuery);
      case EntityType.otp:
        return _fetchOtpHistory(offset, searchQuery);
      case EntityType.document:
        throw UnimplementedError('Document history fetching not implemented');
    }
  }

  Future<List<HistoryItem>> _fetchPasswordHistory(
    int offset,
    String? searchQuery,
  ) async {
    final dao = await ref.read(passwordHistoryDaoProvider.future);
    final cards = await dao.getPasswordHistoryCardsByOriginalId(
      _params.entityId,
      offset,
      pageSize,
      searchQuery,
    );

    logTrace('Cards fetched: ${cards.toString()}', tag: _logTag);

    return cards
        .map(
          (card) => HistoryItem(
            id: card.id,
            originalEntityId: card.originalPasswordId,
            entityType: EntityType.password,
            action: card.action,
            title: card.name,
            subtitle: card.login ?? card.email,
            actionAt: card.actionAt,
          ),
        )
        .toList();
  }

  Future<List<HistoryItem>> _fetchNoteHistory(
    int offset,
    String? searchQuery,
  ) async {
    final dao = await ref.read(noteHistoryDaoProvider.future);
    final cards = await dao.getNoteHistoryCardsByOriginalId(
      _params.entityId,
      offset,
      pageSize,
      searchQuery,
    );

    return cards
        .map(
          (card) => HistoryItem(
            id: card.id,
            originalEntityId: card.originalNoteId,
            entityType: EntityType.note,
            action: card.action,
            title: card.title,
            subtitle: card.description,
            actionAt: card.actionAt,
          ),
        )
        .toList();
  }

  Future<List<HistoryItem>> _fetchBankCardHistory(
    int offset,
    String? searchQuery,
  ) async {
    final dao = await ref.read(bankCardHistoryDaoProvider.future);
    final cards = await dao.getBankCardHistoryCardsByOriginalId(
      _params.entityId,
      offset,
      pageSize,
      searchQuery,
    );

    return cards
        .map(
          (card) => HistoryItem(
            id: card.id,
            originalEntityId: card.originalCardId,
            entityType: EntityType.bankCard,
            action: card.action,
            title: card.name,
            subtitle: card.cardholderName,
            actionAt: card.actionAt,
          ),
        )
        .toList();
  }

  Future<List<HistoryItem>> _fetchFileHistory(
    int offset,
    String? searchQuery,
  ) async {
    final dao = await ref.read(fileHistoryDaoProvider.future);
    final cards = await dao.getFileHistoryCardsByOriginalId(
      _params.entityId,
      offset,
      pageSize,
      searchQuery,
    );

    return cards
        .map(
          (card) => HistoryItem(
            id: card.id,
            originalEntityId: card.originalFileId,
            entityType: EntityType.file,
            action: card.action,
            title: card.name,
            subtitle: null,
            actionAt: card.actionAt,
          ),
        )
        .toList();
  }

  Future<List<HistoryItem>> _fetchOtpHistory(
    int offset,
    String? searchQuery,
  ) async {
    final dao = await ref.read(otpHistoryDaoProvider.future);
    final cards = await dao.getOtpHistoryCardsByOriginalId(
      _params.entityId,
      offset,
      pageSize,
      searchQuery,
    );

    return cards
        .map(
          (card) => HistoryItem(
            id: card.id,
            originalEntityId: card.originalOtpId,
            entityType: EntityType.otp,
            action: card.action,
            title: card.issuer ?? 'OTP',
            subtitle: card.accountName,
            actionAt: card.actionAt,
          ),
        )
        .toList();
  }

  /// Получить общее количество записей
  Future<int> _getTotalCount({String? searchQuery}) async {
    switch (_params.entityType) {
      case EntityType.password:
        final dao = await ref.read(passwordHistoryDaoProvider.future);
        return dao.countPasswordHistoryByOriginalId(
          _params.entityId,
          searchQuery,
        );
      case EntityType.note:
        final dao = await ref.read(noteHistoryDaoProvider.future);
        return dao.countNoteHistoryByOriginalId(_params.entityId, searchQuery);
      case EntityType.bankCard:
        final dao = await ref.read(bankCardHistoryDaoProvider.future);
        return dao.countBankCardHistoryByOriginalId(
          _params.entityId,
          searchQuery,
        );
      case EntityType.file:
        final dao = await ref.read(fileHistoryDaoProvider.future);
        return dao.countFileHistoryByOriginalId(_params.entityId, searchQuery);
      case EntityType.otp:
        final dao = await ref.read(otpHistoryDaoProvider.future);
        return dao.countOtpHistoryByOriginalId(_params.entityId, searchQuery);
      case EntityType.document:
        throw UnimplementedError('Document history count not implemented');
    }
  }

  /// Удалить запись истории из БД
  Future<bool> _deleteHistoryItemFromDb(String historyItemId) async {
    switch (_params.entityType) {
      case EntityType.password:
        final dao = await ref.read(passwordHistoryDaoProvider.future);
        return await dao.deletePasswordHistoryById(historyItemId) > 0;
      case EntityType.note:
        final dao = await ref.read(noteHistoryDaoProvider.future);
        return await dao.deleteNoteHistoryById(historyItemId) > 0;
      case EntityType.bankCard:
        final dao = await ref.read(bankCardHistoryDaoProvider.future);
        return await dao.deleteBankCardHistoryById(historyItemId) > 0;
      case EntityType.file:
        final dao = await ref.read(fileHistoryDaoProvider.future);
        return await dao.deleteFileHistoryById(historyItemId) > 0;
      case EntityType.otp:
        final dao = await ref.read(otpHistoryDaoProvider.future);
        return await dao.deleteOtpHistoryById(historyItemId) > 0;
      case EntityType.document:
        throw UnimplementedError('Document history deletion not implemented');
    }
  }

  /// Удалить всю историю для сущности из БД
  Future<bool> _deleteAllHistoryFromDb() async {
    switch (_params.entityType) {
      case EntityType.password:
        final dao = await ref.read(passwordHistoryDaoProvider.future);
        return await dao.deletePasswordHistoryByPasswordId(_params.entityId) >=
            0;
      case EntityType.note:
        final dao = await ref.read(noteHistoryDaoProvider.future);
        return await dao.deleteNoteHistoryByNoteId(_params.entityId) >= 0;
      case EntityType.bankCard:
        final dao = await ref.read(bankCardHistoryDaoProvider.future);
        return await dao.deleteBankCardHistoryByOriginalId(_params.entityId) >=
            0;
      case EntityType.file:
        final dao = await ref.read(fileHistoryDaoProvider.future);
        return await dao.deleteFileHistoryByFileId(_params.entityId) >= 0;
      case EntityType.otp:
        final dao = await ref.read(otpHistoryDaoProvider.future);
        return await dao.deleteOtpHistoryByOtpId(_params.entityId) >= 0;
      case EntityType.document:
        throw UnimplementedError('Document history deletion not implemented');
    }
  }
}
