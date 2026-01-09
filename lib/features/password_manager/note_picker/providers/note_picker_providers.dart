import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/note_picker/models/note_picker_models.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/notes_filter.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

const int pageSize = 20;

/// Provider для фильтра заметок
final notePickerFilterProvider =
    NotifierProvider<NotePickerFilterNotifier, NotesFilter>(
      NotePickerFilterNotifier.new,
    );

class NotePickerFilterNotifier extends Notifier<NotesFilter> {
  @override
  NotesFilter build() {
    return NotesFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: NotesSortField.modifiedAt,
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
      base: state.base.copyWith(offset: (state.base.offset ?? 0) + pageSize),
    );
  }

  /// Сбросить фильтр
  void reset() {
    state = NotesFilter.create(
      base: BaseFilter.create(
        query: '',
        limit: pageSize,
        offset: 0,
        sortDirection: SortDirection.desc,
      ),
      sortField: NotesSortField.modifiedAt,
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
    final mainStoreAsync = ref.read(mainStoreProvider);

    final mainStore = mainStoreAsync.value;
    if (mainStore == null || !mainStore.isOpen) {
      Toaster.error(title: 'Ошибка', description: 'База данных не открыта');
      return;
    }

    try {
      final manager = await ref.read(mainStoreManagerProvider.future);
      if (manager == null || manager.currentStore == null) {
        Toaster.error(title: 'Ошибка', description: 'База данных недоступна');
        return;
      }

      final dao = manager.currentStore!.noteFilterDao;
      final notes = await dao.getFiltered(filter);
      final total = await dao.countFiltered(filter);

      // Исключаем текущую заметку из списка
      final filteredNotes = excludeNoteId != null
          ? notes.where((note) => note.id != excludeNoteId).toList()
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

    final mainStoreAsync = ref.read(mainStoreProvider);

    final mainStore = mainStoreAsync.value;
    if (mainStore == null || !mainStore.isOpen) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    try {
      // Увеличиваем offset
      ref.read(notePickerFilterProvider.notifier).incrementOffset();
      final updatedFilter = ref.read(notePickerFilterProvider);

      final manager = await ref.read(mainStoreManagerProvider.future);
      if (manager == null || manager.currentStore == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final dao = manager.currentStore!.noteFilterDao;
      final newNotes = await dao.getFiltered(updatedFilter);
      final total = await dao.countFiltered(updatedFilter);

      // Исключаем текущую заметку из новых данных
      final filteredNewNotes = state.excludeNoteId != null
          ? newNotes.where((note) => note.id != state.excludeNoteId).toList()
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
}
