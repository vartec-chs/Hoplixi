import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/dashboard_list_refresh_trigger_provider.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/custom_fields_helpers.dart';
import 'package:hoplixi/features/password_manager/shared/widgets/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';
import 'package:hoplixi/vault_db/core/services/entities/document_service.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
import 'package:hoplixi/vault_db/providers/service_providers.dart';
import 'package:hoplixi/vault_db/services/other/document_storage_service.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../models/document_form_state.dart';

const _logTag = 'DocumentFormProvider';

/// Провайдер состояния формы документа
final documentFormProvider =
    NotifierProvider.autoDispose<DocumentFormNotifier, DocumentFormState>(
      DocumentFormNotifier.new,
    );

/// Notifier для управления формой документа
class DocumentFormNotifier extends Notifier<DocumentFormState> {
  @override
  DocumentFormState build() {
    return const DocumentFormState(isEditMode: false);
  }

  /// Инициализировать форму для создания новой документа
  void initForCreate() {
    state = const DocumentFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования документа
  Future<void> initForEdit(String documentId) async {
    state = state.copyWith(isLoading: true);

    try {
      final repositories = await ref.read(vaultRepositories.future);
      final relationsService = await ref.read(
        vaultItemRelationsServiceProvider.future,
      );
      final viewResult = await repositories.document.getViewById(documentId);

      final view = viewResult.getOrThrow().getOrNull();

      if (view == null) {
        logWarning('Document not found: $documentId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      final item = view.item;
      final docItem = view.document;

      DocumentType? documentType;
      if (docItem.currentVersionId != null) {
        final versionResult = await repositories.documentVersion.getVersionById(
          docItem.currentVersionId!,
        );
        final version = versionResult.getOrThrow().getOrNull();
        if (version != null) {
          documentType = version.documentType;
        }
      }

      // Load tags
      final tagIdsResult = await relationsService.getTagIdsForItem(documentId);
      final tagIds = tagIdsResult.getOrThrow();
      final tagRecordsResult = await repositories.tag.getTagsByIds(tagIds);
      final tagRecords = tagRecordsResult.getOrThrow();

      final customFields = await loadCustomFields(ref, documentId);

      // Получаем категорию документа
      String? categoryName;
      if (item.categoryId != null) {
        final catResult = await repositories.category.getCategory(
          item.categoryId!,
        );
        categoryName = catResult.getOrThrow().getOrNull()?.name;
      }

      // Получаем заметку документа
      // TODO: In new architecture, notes are linked via ItemLinkRepository or RelationsService
      String? noteId;
      String? noteName;

      // Получаем страницы документа
      final documentService = await ref.read(
        documentStorageServiceProvider.future,
      );
      final pagesData = await documentService.getDocumentPages(documentId);

      // Преобразуем страницы в DocumentPageInfo
      final pages = <DocumentPageInfo>[];
      for (final pageData in pagesData) {
        // Получаем информацию о файле страницы
        if (pageData.metadataId == null) continue;

        final metadataResult = await repositories.fileMetadata.getMetadataById(
          pageData.metadataId!,
        );
        final metadata = metadataResult.getOrThrow().getOrNull();

        String fileName = 'Страница ${pageData.pageNumber}';
        int fileSize = 0;
        String? mimeType;

        if (metadata != null) {
          fileName = metadata.fileName;
          fileSize = metadata.fileSize;
          mimeType = metadata.mimeType;
        }

        pages.add(
          DocumentPageInfo(
            pageId: pageData.id,
            fileId: pageData.metadataId!,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            pageNumber: pageData.pageNumber,
            isPrimary: pageData.isPrimary,
            isNew: false,
          ),
        );
      }

      state = DocumentFormState(
        isEditMode: true,
        editingDocumentId: documentId,
        title: item.name,
        documentType: documentType,
        description: item.description ?? '',
        pages: pages,
        categoryId: item.categoryId,
        categoryName: categoryName,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
        customFields: customFields,
        noteId: noteId,
        noteName: noteName,
        isLoading: false,
      );
    } catch (e, stack) {
      logError(
        'Failed to load document for editing',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Выбрать файлы страниц через FilePicker
  Future<void> pickPages() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'tiff'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final newPages = <DocumentPageInfo>[];
      final startPageNumber = state.pages.length + 1;

      for (int i = 0; i < result.files.length; i++) {
        final pickedFile = result.files[i];
        if (pickedFile.path == null) continue;

        final file = File(pickedFile.path!);
        final fileName = pickedFile.name;
        final fileSize = pickedFile.size;
        final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

        newPages.add(
          DocumentPageInfo(
            file: file,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            pageNumber: startPageNumber + i,
            isPrimary: state.pages.isEmpty && i == 0,
            isNew: true,
          ),
        );
      }

      final updatedPages = [...state.pages, ...newPages];

      state = state.copyWith(
        pages: updatedPages,
        pagesError: null,
        // Автозаполнение названия если пустое
        title: state.title.isEmpty && newPages.isNotEmpty
            ? p.basenameWithoutExtension(newPages.first.fileName)
            : state.title,
      );

      logInfo(
        'Added ${newPages.length} pages, total: ${updatedPages.length}',
        tag: _logTag,
      );
    } catch (e, stack) {
      logError(
        'Failed to pick pages',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(pagesError: 'Ошибка при выборе файлов');
    }
  }

  /// Добавить страницы из drag-and-drop
  Future<void> addDroppedPages(List<XFile> xFiles) async {
    try {
      final newPages = <DocumentPageInfo>[];
      final startPageNumber = state.pages.length + 1;

      for (int i = 0; i < xFiles.length; i++) {
        final xFile = xFiles[i];
        final file = File(xFile.path);
        final fileName = p.basename(xFile.path);
        final fileSize = await file.length();
        final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

        newPages.add(
          DocumentPageInfo(
            file: file,
            fileName: fileName,
            fileSize: fileSize,
            mimeType: mimeType,
            pageNumber: startPageNumber + i,
            isPrimary: state.pages.isEmpty && i == 0,
            isNew: true,
          ),
        );
      }

      final updatedPages = [...state.pages, ...newPages];
      state = state.copyWith(
        pages: updatedPages,
        pagesError: null,
        title: state.title.isEmpty && newPages.isNotEmpty
            ? p.basenameWithoutExtension(newPages.first.fileName)
            : state.title,
      );
    } catch (e, stack) {
      logError(
        'Failed to add dropped pages',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(pagesError: 'Ошибка при загрузке файлов');
    }
  }

  /// Сканировать страницы через камеру (только мобильные)
  Future<void> scanPages() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      logWarning('Scanning is only supported on mobile', tag: _logTag);
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      state = state.copyWith(
        pagesError: 'Нет разрешения на использование камеры',
      );
      return;
    }

    try {
      final scannedDocs = await FlutterDocScanner()
          .getScannedDocumentAsImages();

      if (scannedDocs == null) {
        logInfo('No documents scanned', tag: _logTag);
        return;
      }

      logTrace('Scanned docs: $scannedDocs', tag: _logTag);

      final paths = scannedDocs.images;

      final newPages = <DocumentPageInfo>[];
      final startPageNumber = state.pages.length + 1;

      for (int i = 0; i < paths.length; i++) {
        final path = paths[i];
        final file = File(path);

        if (!await file.exists()) continue;

        // Перемещаем файл в кэш приложения для безопасности и удаляем исходный
        File processedFile = file;
        try {
          final tempDir = Directory.systemTemp;
          final newName =
              'scan_${DateTime.now().millisecondsSinceEpoch}_$i${p.extension(path)}';
          final newPath = p.join(tempDir.path, newName);

          try {
            processedFile = await file.rename(newPath);
          } catch (_) {
            // Если rename не сработал (разные файловые системы), копируем и удаляем
            processedFile = await file.copy(newPath);
            await file.delete();
          }
          logInfo('Moved scanned file to: $newPath', tag: _logTag);
        } catch (e) {
          logError('Failed to move scanned file', error: e, tag: _logTag);
          // Продолжаем с исходным файлом если не удалось переместить
        }

        final length = await processedFile.length();
        final mimeType = lookupMimeType(processedFile.path) ?? 'image/jpeg';

        newPages.add(
          DocumentPageInfo(
            file: processedFile,
            fileName: 'Скан ${startPageNumber + i}.jpg',
            fileSize: length,
            mimeType: mimeType,
            pageNumber: startPageNumber + i,
            isPrimary: state.pages.isEmpty && i == 0,
            isNew: true,
          ),
        );
      }

      if (newPages.isNotEmpty) {
        final updatedPages = [...state.pages, ...newPages];
        state = state.copyWith(
          pages: updatedPages,
          pagesError: null,
          title: state.title.isEmpty && newPages.isNotEmpty
              ? 'Скан документа'
              : state.title,
        );

        logInfo(
          'Added ${newPages.length} scanned pages, total: ${updatedPages.length}',
          tag: _logTag,
        );
      }
    } catch (e, stack) {
      logError(
        'Failed to scan pages',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(pagesError: 'Ошибка при сканировании');
    }
  }

  /// Удалить страницу по индексу
  void removePage(int index) {
    if (index < 0 || index >= state.pages.length) return;

    final updatedPages = [...state.pages];
    final removedPage = updatedPages.removeAt(index);

    // Перенумеруем оставшиеся страницы
    for (int i = 0; i < updatedPages.length; i++) {
      updatedPages[i] = updatedPages[i].copyWith(pageNumber: i + 1);
    }

    // Если удалена главная страница, назначаем первую как главную
    if (removedPage.isPrimary && updatedPages.isNotEmpty) {
      updatedPages[0] = updatedPages[0].copyWith(isPrimary: true);
    }

    state = state.copyWith(pages: updatedPages);

    logInfo('Removed page at index $index', tag: _logTag);
  }

  /// Установить страницу как главную (обложку)
  void setPrimaryPage(int index) {
    if (index < 0 || index >= state.pages.length) return;

    final updatedPages = state.pages.map((page) {
      return page.copyWith(isPrimary: page.pageNumber == index + 1);
    }).toList();

    state = state.copyWith(pages: updatedPages);

    logInfo('Set page ${index + 1} as primary', tag: _logTag);
  }

  /// Переместить страницу
  void movePage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.pages.length) return;
    if (newIndex < 0 || newIndex >= state.pages.length) return;
    if (oldIndex == newIndex) return;

    final updatedPages = [...state.pages];
    final page = updatedPages.removeAt(oldIndex);
    updatedPages.insert(newIndex, page);

    // Перенумеруем страницы
    for (int i = 0; i < updatedPages.length; i++) {
      updatedPages[i] = updatedPages[i].copyWith(pageNumber: i + 1);
    }

    state = state.copyWith(pages: updatedPages);

    logInfo('Moved page from $oldIndex to $newIndex', tag: _logTag);
  }

  /// Обновить поле title
  void setTitle(String value) {
    state = state.copyWith(title: value, titleError: _validateTitle(value));
  }

  /// Обновить поле documentType
  void setDocumentType(DocumentType? value) {
    state = state.copyWith(documentType: value);
  }

  /// Обновить поле description
  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  /// Обновить категорию
  void setCategory(String? categoryId, String? categoryName) {
    state = state.copyWith(categoryId: categoryId, categoryName: categoryName);
  }

  /// Обновить заметку
  void setNote(String? noteId, String? noteName) {
    state = state.copyWith(noteId: noteId, noteName: noteName);
  }

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
  }

  void setCustomFields(List<CustomFieldEntry> fields) {
    state = state.copyWith(customFields: fields);
  }

  /// Валидация названия
  String? _validateTitle(String value) {
    if (value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.trim().length > 255) {
      return 'Название не должно превышать 255 символов';
    }
    return null;
  }

  /// Валидация страниц
  String? _validatePages() {
    if (!state.isEditMode && state.pages.isEmpty) {
      return 'Добавьте хотя бы одну страницу';
    }
    return null;
  }

  /// Валидировать все поля формы
  bool validateAll() {
    final titleError = _validateTitle(state.title);
    final pagesError = _validatePages();

    state = state.copyWith(titleError: titleError, pagesError: pagesError);

    return !state.hasErrors;
  }

  /// Сохранить форму
  Future<bool> save() async {
    if (!validateAll()) {
      logWarning('Form validation failed', tag: _logTag);
      return false;
    }

    state = state.copyWith(isSaving: true, totalPages: state.pages.length);

    try {
      final services = await ref.read(vaultEntityServices.future);
      final documentStorageService = await ref.read(
        documentStorageServiceProvider.future,
      );

      if (state.isEditMode && state.editingDocumentId != null) {
        // Режим редактирования
        return await _updateDocument(services.document, documentStorageService);
      } else {
        // Режим создания
        return await _createDocument(documentStorageService);
      }
    } catch (e, stack) {
      logError(
        'Failed to save document',
        error: e,
        stackTrace: stack,
        tag: _logTag,
      );
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Создать новый документ
  Future<bool> _createDocument(DocumentStorageService documentService) async {
    final newPages = state.pages
        .where((p) => p.isNew && p.file != null)
        .toList();

    if (newPages.isEmpty) {
      state = state.copyWith(
        isSaving: false,
        pagesError: 'Нет страниц для загрузки',
      );
      return false;
    }

    final pageFiles = newPages.map((p) => p.file!).toList();

    final documentId = await documentService.createDocumentWithPages(
      title: state.title.trim(),
      documentType: state.documentType,
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
      categoryId: state.categoryId,
      noteId: state.noteId,
      tagsIds: state.tagIds,
      pageFiles: pageFiles,
      onProgress: (current, total) {
        state = state.copyWith(
          currentUploadingPage: current,
          totalPages: total,
          uploadProgress: current / total,
        );
      },
    );

    await saveCustomFields(ref, documentId, state.customFields);

    logInfo('Document created: $documentId', tag: _logTag);
    state = state.copyWith(isSaving: false, isSaved: true);

    ref
        .read(dashboardListRefreshTriggerProvider.notifier)
        .triggerEntityAdd(EntityType.document, entityId: documentId);

    return true;
  }

  /// Обновить существующий документ
  Future<bool> _updateDocument(
    DocumentService documentService,
    DocumentStorageService documentStorageService,
  ) async {
    final documentId = state.editingDocumentId!;

    // Обновляем метаданные документа
    final res = await documentService.update(
      PatchDocumentDto(
        item: VaultItemPatchDto(
          itemId: documentId,
          name: FieldUpdate.set(state.title.trim()),
          description: FieldUpdate.set(
            state.description.trim().isEmpty ? null : state.description.trim(),
          ),
          categoryId: FieldUpdate.set(state.categoryId),
        ),
        document: const PatchDocumentDataDto(),
        tags: FieldUpdate.set(state.tagIds),
      ),
    );

    res.getOrThrow();

    // TODO: handle noteId link update

    // Добавляем новые страницы если есть
    final newPages = state.pages
        .where((p) => p.isNew && p.file != null)
        .toList();

    if (newPages.isNotEmpty) {
      final pageFiles = newPages.map((p) => p.file!).toList();

      await documentStorageService.addPagesToDocument(
        documentId: documentId,
        pageFiles: pageFiles,
        onProgress: (current, total) {
          state = state.copyWith(
            currentUploadingPage: current,
            totalPages: total,
            uploadProgress: current / total,
          );
        },
      );
    }

    await saveCustomFields(ref, documentId, state.customFields);

    logInfo('Document updated: $documentId', tag: _logTag);
    state = state.copyWith(isSaving: false, isSaved: true);

    ref
        .read(dashboardListRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.document, entityId: documentId);

    return true;
  }

  /// Сбросить флаг сохранения
  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}
