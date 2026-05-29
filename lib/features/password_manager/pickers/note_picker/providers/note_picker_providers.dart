import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/pickers/note_picker/models/note_picker_models.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/services/entities/vault_card_filter_service.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:result_dart/result_dart.dart';

const int pageSize = 20;

/// Provider для фильтра заметок
final notePickerFilterProvider =
    NotifierProvider<NotePickerFilterNotifier, NoteFilter>(
      NotePickerFilterNotifier.new,
    );

class NotePickerFilterNotifier extends Notifier<NoteFilter> {
  @override
  NoteFilter build() {
    return NoteFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: NoteSortField.modifiedAt,
    );
  }

  /// Обновить поисковый запрос
  void updateQuery(String query) {
    state = state.copyWith(
      base: state.base.copyWith(query: query.trim(), offset: 0),
    );
  }

  /// Увеличить offset для пагинации
  void incrementOffset() {
    state = state.copyWith(
      base: state.base.copyWith(offset: state.base.offset + pageSize),
    );
  }

  /// Сбросить фильтр
  void reset() {
    state = NoteFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: NoteSortField.modifiedAt,
    );
  }
}

/// Provider для загруженных данных заметок
final notePickerDataProvider =
    NotifierProvider<NotePickerDataNotifier, NotePickerData>(
      NotePickerDataNotifier.new,
    );

class NotePickerDataNotifier extends Notifier<NotePickerData> {
  @override
  NotePickerData build() {
    return const NotePickerData();
  }

  /// Загрузить первую страницу заметок
  Future<void> loadInitial(String? excludeNoteId) async {
    final filter = ref.read(notePickerFilterProvider);
    final service = await _getService();
    if (service == null) return;

    try {
      final notes = (await service.getNotes(filter)).getOrThrow();
      final total = (await service.countNotes(filter)).getOrThrow();

      // Исключаем текущую заметку из списка
      final filteredNotes = excludeNoteId != null
          ? notes.where((note) => note.card.item.itemId != excludeNoteId).toList()
          : notes;

      state = NotePickerData(
        notes: filteredNotes,
        hasMore: filteredNotes.length < total,
        isLoadingMore: false,
        excludeNoteId: excludeNoteId,
      );
    } catch (e) {
      Toaster.error(title: 'Ошибка загрузки', description: e.toString());
    }
  }

  /// Загрузить следующую страницу заметок
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final service = await _getService();
    if (service == null) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      // Увеличиваем offset
      ref.read(notePickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(notePickerFilterProvider);

      final newNotes = (await service.getNotes(updatedFilter)).getOrThrow();
      final total = (await service.countNotes(updatedFilter)).getOrThrow();

      // Исключаем текущую заметку из новых данных
      final filteredNewNotes = state.excludeNoteId != null
          ? newNotes
                .where((note) => note.card.item.itemId != state.excludeNoteId)
                .toList()
          : newNotes;

      final allNotes = [...state.notes, ...filteredNewNotes];

      state = NotePickerData(
        notes: allNotes,
        hasMore: allNotes.length < total,
        isLoadingMore: false,
        excludeNoteId: state.excludeNoteId,
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
