import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

import '../models/note_form_state.dart';

const _logTag = 'NoteFormProvider';

/// Провайдер состояния формы заметки
final noteFormProvider =
    NotifierProvider.autoDispose<NoteFormNotifier, NoteFormState>(
      NoteFormNotifier.new,
    );

/// Notifier для управления формой заметки
class NoteFormNotifier extends Notifier<NoteFormState> {
  @override
  NoteFormState build() {
    return const NoteFormState(isEditMode: false);
  }

  /// Инициализировать форму для создания новой заметки
  void initForCreate() {
    state = const NoteFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования заметки
  Future<void> initForEdit(String noteId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dao = await ref.read(noteDaoProvider.future);
      final record = await dao.getById(noteId);

      if (record == null) {
        logWarning('Note not found: $noteId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final (vault, noteItem) = record;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      final tagIds = await vaultItemDao.getTagIds(noteId);
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagRecords = await tagDao.getTagsByIds(tagIds);

      state = NoteFormState(
        isEditMode: true,
        editingNoteId: noteId,
        title: vault.name,
        content: noteItem.content,
        deltaJson: noteItem.deltaJson,
        description: vault.description ?? '',
        categoryId: vault.categoryId,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
        isLoading: false,
        originalTitle: vault.name,
        originalDeltaJson: noteItem.deltaJson,
        originalDescription: vault.description ?? '',
        originalCategoryId: vault.categoryId,
        originalTagIds: tagIds,
        edited: false,
      );
    } catch (e, stack) {
      logError(
        'Failed to load note for editing',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Обновить заголовок
  void setTitle(String value) {
    state = state.copyWith(
      title: value,
      titleError: _validateTitle(value),
      hasUnsavedChanges: true,
    );
  }

  /// Обновить контент (plain text)
  void setContent(String value) {
    state = state.copyWith(
      content: value,
      contentError: _validateContent(value),
      hasUnsavedChanges: true,
    );
  }

  /// Обновить delta JSON (структура Quill документа)
  void setDeltaJson(String value) {
    state = state.copyWith(deltaJson: value, hasUnsavedChanges: true);
  }

  /// Обновить контент из QuillController
  void updateFromController(QuillController controller) {
    final plainText = controller.document.toPlainText();
    final deltaJson = jsonEncode(controller.document.toDelta().toJson());

    // Извлекаем ID связанных заметок из deltaJson
    final linkedNoteIds = _extractLinkedNoteIds(deltaJson);

    // Проверяем, изменилось ли что-то относительно исходных данных
    final hasRealChanges = _checkIfDataChanged(
      deltaJson: deltaJson,
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      tagIds: state.tagIds,
    );

    state = state.copyWith(
      content: plainText,
      deltaJson: deltaJson,
      linkedNoteIds: linkedNoteIds,
      contentError: _validateContent(plainText),
      hasUnsavedChanges: true,
      // Устанавливаем флаг edited только если есть реальные изменения
      edited: state.isEditMode ? hasRealChanges : state.edited,
    );
  }

  /// Проверить, изменились ли данные относительно исходного состояния
  bool _checkIfDataChanged({
    required String deltaJson,
    required String title,
    required String description,
    required String? categoryId,
    required List<String> tagIds,
  }) {
    if (!state.isEditMode) return false;

    // Сравниваем с исходными данными
    if (deltaJson != state.originalDeltaJson) return true;
    if (title != state.originalTitle) return true;
    if (description != state.originalDescription) return true;
    if (categoryId != state.originalCategoryId) return true;

    // Сравниваем списки тегов
    if (tagIds.length != state.originalTagIds.length) return true;
    if (!tagIds.toSet().containsAll(state.originalTagIds)) return true;
    if (!state.originalTagIds.toSet().containsAll(tagIds)) return true;

    return false;
  }

  /// Установить флаг edited
  void markAsEdited() {
    if (state.isEditMode) {
      state = state.copyWith(edited: true);
    }
  }

  /// Извлечь ID связанных заметок из deltaJson
  List<String> _extractLinkedNoteIds(String deltaJson) {
    final noteIdPattern = RegExp(r'note://([a-f0-9-]+)');

    final matches = noteIdPattern.allMatches(deltaJson);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  /// Обновить описание
  void setDescription(String value) {
    state = state.copyWith(description: value, hasUnsavedChanges: true);
  }

  /// Обновить категорию
  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(
      categoryId: categoryId,
      categoryName: categoryName,
      hasUnsavedChanges: true,
    );
  }

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(
      tagIds: tagIds,
      tagNames: tagNames,
      hasUnsavedChanges: true,
    );
  }

  /// Валидация заголовка
  String? _validateTitle(String value) {
    if (value.trim().isEmpty) {
      return 'Заголовок обязателен';
    }
    if (value.trim().length > 255) {
      return 'Заголовок не должен превышать 255 символов';
    }
    return null;
  }

  /// Валидация контента
  String? _validateContent(String value) {
    if (value.trim().isEmpty) {
      return 'Содержание не может быть пустым';
    }
    return null;
  }

  /// Валидировать все поля формы
  bool validateAll() {
    final titleError = _validateTitle(state.title);
    final contentError = _validateContent(state.content);

    state = state.copyWith(titleError: titleError, contentError: contentError);

    return !state.hasErrors;
  }

  /// Сохранить форму
  Future<bool> save() async {
    // Валидация
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final dao = await ref.read(noteDaoProvider.future);

      if (state.isEditMode && state.editingNoteId != null) {
        // Режим редактирования
        final dto = UpdateNoteDto(
          title: state.title.trim(),
          content: state.content.trim(),
          deltaJson: state.deltaJson,
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          categoryId: state.categoryId,
        );

        final success = await dao.updateNote(state.editingNoteId!, dto);

        if (success) {
          // Синхронизация тегов
          final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
          await vaultItemDao.syncTags(state.editingNoteId!, state.tagIds);

          logInfo('Note updated: ${state.editingNoteId}', tag: _logTag);
          state = state.copyWith(
            isSaving: false,
            isSaved: true,
            hasUnsavedChanges: false,
          );

          // Триггерим обновление списка заметок
          ref
              .read(dataRefreshTriggerProvider.notifier)
              .triggerEntityUpdate(
                EntityType.note,
                entityId: state.editingNoteId,
              );

          return true;
        } else {
          logWarning(
            'Failed to update note: ${state.editingNoteId}',
            tag: _logTag,
          );
          state = state.copyWith(isSaving: false);
          return false;
        }
      } else {
        // Режим создания
        final dto = CreateNoteDto(
          title: state.title.trim(),
          content: state.content.trim(),
          deltaJson: state.deltaJson,
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          categoryId: state.categoryId,
          tagsIds: state.tagIds.isEmpty ? null : state.tagIds,
        );

        final noteId = await dao.createNote(dto);

        logInfo('Note created: $noteId', tag: _logTag);
        state = state.copyWith(
          isSaving: false,
          isSaved: true,
          hasUnsavedChanges: false,
        );

        // Триггерим обновление списка заметок
        ref
            .read(dataRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.note, entityId: noteId);

        return true;
      }
    } catch (e, stack) {
      logError(
        'Failed to save note',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Сбросить флаг сохранения
  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }

  /// Сбросить флаг несохраненных изменений
  void resetUnsavedChanges() {
    state = state.copyWith(hasUnsavedChanges: false);
  }
}
