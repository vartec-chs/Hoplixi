import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/main_db/core/old/models/dto/file_dto.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/main_db/providers/other/service_providers.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../models/file_form_state.dart';

const _logTag = 'FileFormProvider';

/// Провайдер состояния формы файла
final fileFormProvider =
    NotifierProvider.autoDispose<FileFormNotifier, FileFormState>(
      FileFormNotifier.new,
    );

/// Notifier для управления формой файла
class FileFormNotifier extends Notifier<FileFormState> {
  @override
  FileFormState build() {
    return const FileFormState(isEditMode: false);
  }

  /// Инициализировать форму для создания нового файла
  void initForCreate() {
    state = const FileFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования файла
  Future<void> initForEdit(String fileId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dao = await ref.read(fileDaoProvider.future);
      final record = await dao.getById(fileId);

      if (record == null) {
        logWarning('File not found: $fileId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final (vault, fileItem) = record;
      final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
      final tagIds = await vaultItemDao.getTagIds(fileId);
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagRecords = await tagDao.getTagsByIds(tagIds);
      final customFields = await loadCustomFields(ref, fileId);

      // Получаем FileMetadata через metadataId
      String? existingFileName;
      int? existingFileSize;
      String? existingFileExtension;

      if (fileItem.metadataId != null) {
        final metadata = await (dao.attachedDatabase.select(
          dao.attachedDatabase.fileMetadata,
        )..where((m) => m.id.equals(fileItem.metadataId!))).getSingleOrNull();

        if (metadata != null) {
          existingFileName = metadata.fileName;
          existingFileSize = metadata.fileSize;
          existingFileExtension = metadata.fileExtension;
        }
      }

      state = FileFormState(
        isEditMode: true,
        editingFileId: fileId,
        name: vault.name,
        description: vault.description ?? '',
        existingFileName: existingFileName,
        existingFileSize: existingFileSize,
        existingFileExtension: existingFileExtension,
        categoryId: vault.categoryId,
        noteId: vault.noteId,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
        customFields: customFields,
        isLoading: false,
      );
    } catch (e, stack) {
      logError(
        'Failed to load file for editing',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Выбрать файл через FilePicker
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.first;
      if (pickedFile.path == null) {
        state = state.copyWith(fileError: 'Не удалось получить путь к файлу');
        return;
      }

      final file = File(pickedFile.path!);
      final fileName = pickedFile.name;
      final fileSize = pickedFile.size;
      final fileExtension = p.extension(fileName);
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      state = state.copyWith(
        selectedFile: file,
        selectedFileName: fileName,
        selectedFileSize: fileSize,
        selectedFileExtension: fileExtension,
        selectedFileMimeType: mimeType,
        fileError: null,
        // Автозаполнение имени если пустое
        name: state.name.isEmpty
            ? p.basenameWithoutExtension(fileName)
            : state.name,
      );

      logInfo('File selected: $fileName ($fileSize bytes)', tag: _logTag);
    } catch (e, stack) {
      logError(
        'Failed to pick file',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(fileError: 'Ошибка при выборе файла');
    }
  }

  /// Установить файл из drag-and-drop
  Future<void> setDroppedFile(XFile xFile) async {
    try {
      final file = File(xFile.path);
      final fileName = p.basename(xFile.path);
      final fileSize = await file.length();
      final fileExtension = p.extension(fileName);
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      state = state.copyWith(
        selectedFile: file,
        selectedFileName: fileName,
        selectedFileSize: fileSize,
        selectedFileExtension: fileExtension,
        selectedFileMimeType: mimeType,
        fileError: null,
        name: state.name.isEmpty
            ? p.basenameWithoutExtension(fileName)
            : state.name,
      );
    } catch (e, stack) {
      logError(
        'Failed to set dropped file',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(fileError: 'Ошибка при загрузке файла');
    }
  }

  /// Удалить выбранный файл
  void clearSelectedFile() {
    state = state.copyWith(
      selectedFile: null,
      selectedFileName: null,
      selectedFileSize: null,
      selectedFileExtension: null,
      selectedFileMimeType: null,
    );
  }

  /// Обновить поле name
  void setName(String value) {
    state = state.copyWith(name: value, nameError: _validateName(value));
  }

  /// Обновить поле description
  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  /// Обновить поле noteId
  void setNoteId(String? value) {
    state = state.copyWith(noteId: value);
  }

  /// Обновить категорию
  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  void setCustomFields(List<CustomFieldEntry> fields) {
    state = state.copyWith(customFields: fields);
  }

  /// Валидация имени
  String? _validateName(String value) {
    if (value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.trim().length > 255) {
      return 'Название не должно превышать 255 символов';
    }
    return null;
  }

  /// Валидация файла
  String? _validateFile() {
    if (!state.isEditMode && state.selectedFile == null) {
      return 'Выберите файл для загрузки';
    }
    return null;
  }

  /// Валидировать все поля формы
  bool validateAll() {
    final nameError = _validateName(state.name);
    final fileError = _validateFile();

    state = state.copyWith(nameError: nameError, fileError: fileError);

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
      final dao = await ref.read(fileDaoProvider.future);

      if (state.isEditMode && state.editingFileId != null) {
        // Режим редактирования (только метаданные)
        final dto = UpdateFileDto(
          name: state.name.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          noteId: state.noteId,
          categoryId: state.categoryId,
          tagsIds: state.tagIds,
        );

        final success = await dao.updateFile(state.editingFileId!, dto);

        if (success) {
          // Если выбран новый файл, обновляем содержимое
          if (state.selectedFile != null) {
            final fileStorageService = await ref.read(
              fileStorageServiceProvider.future,
            );

            await fileStorageService.updateFileContent(
              fileId: state.editingFileId!,
              newFile: state.selectedFile!,
              onProgress: (percentage) {
                state = state.copyWith(uploadProgress: percentage / 100.0);
              },
            );
            logInfo(
              'File content updated: ${state.editingFileId}',
              tag: _logTag,
            );
          }

          // Синхронизация тегов уже происходит в dao.updateFile() через dto.tagsIds

          await saveCustomFields(ref, state.editingFileId!, state.customFields);

          logInfo('File updated: ${state.editingFileId}', tag: _logTag);
          state = state.copyWith(isSaving: false, isSaved: true);

          // Триггерим обновление списка файлов
          ref
              .read(dashboardListRefreshTriggerProvider.notifier)
              .triggerEntityUpdate(
                EntityType.file,
                entityId: state.editingFileId,
              );

          return true;
        } else {
          logWarning(
            'Failed to update file: ${state.editingFileId}',
            tag: _logTag,
          );
          state = state.copyWith(isSaving: false);
          return false;
        }
      } else {
        // Режим создания - загрузка и шифрование файла
        final fileStorageService = await ref.read(
          fileStorageServiceProvider.future,
        );

        final fileId = await fileStorageService.importFile(
          sourceFile: state.selectedFile!,
          name: state.name.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          categoryId: state.categoryId,
          noteId: state.noteId,
          tagsIds: state.tagIds,
          onProgress: (percentage) {
            state = state.copyWith(uploadProgress: percentage / 100.0);
          },
        );

        await saveCustomFields(ref, fileId, state.customFields);

        logInfo('File created: $fileId', tag: _logTag);
        state = state.copyWith(isSaving: false, isSaved: true);

        // Триггерим обновление списка файлов
        ref
            .read(dashboardListRefreshTriggerProvider.notifier)
            .triggerEntityAdd(EntityType.file, entityId: fileId);

        return true;
      }
    } catch (e, stack) {
      logError(
        'Failed to save file',
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
}
