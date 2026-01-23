import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_store/dao/index.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/main_store/provider/service_providers.dart';
import 'package:hoplixi/main_store/services/index.dart';
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

  /// Инициализировать форму для создания нового документа
  void initForCreate() {
    state = const DocumentFormState(isEditMode: false);
  }

  /// Инициализировать форму для редактирования документа
  Future<void> initForEdit(String documentId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dao = await ref.read(documentDaoProvider.future);
      final document = await dao.getDocumentById(documentId);

      if (document == null) {
        logWarning('Document not found: $documentId', tag: _logTag);
        state = state.copyWith(isLoading: false);
        return;
      }

      // Получаем теги документа
      final tagDao = await ref.read(tagDaoProvider.future);
      final tagIds = await dao.getDocumentTagIds(documentId);
      final tagRecords = await tagDao.getTagsByIds(tagIds);

      // Получаем страницы документа
      final documentService = await ref.read(
        documentStorageServiceProvider.future,
      );
      final pagesData = await documentService.getDocumentPages(documentId);

      // Преобразуем страницы в DocumentPageInfo
      final pages = <DocumentPageInfo>[];
      for (final pageData in pagesData) {
        // Получаем информацию о файле страницы
        final fileDao = await ref.read(fileDaoProvider.future);
        final fileInfo = await fileDao.getFileById(pageData.metadataId!);

        String fileName = 'Страница ${pageData.pageNumber}';
        int fileSize = 0;
        String? mimeType;

        if (fileInfo != null && fileInfo.metadataId != null) {
          final metadata = await (fileDao.attachedDatabase.select(
            fileDao.attachedDatabase.fileMetadata,
          )..where((m) => m.id.equals(fileInfo.metadataId!))).getSingleOrNull();

          if (metadata != null) {
            fileName = metadata.fileName ?? fileName;
            fileSize = metadata.fileSize ?? 0;
            mimeType = metadata.mimeType;
          }
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
        title: document.title ?? '',
        documentType: document.documentType,
        description: document.description ?? '',
        pages: pages,
        categoryId: document.categoryId,
        tagIds: tagIds,
        tagNames: tagRecords.map((tag) => tag.name).toList(),
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
      final result = await FilePicker.platform.pickFiles(
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

      if (scannedDocs is List) {
        final newPages = <DocumentPageInfo>[];
        final startPageNumber = state.pages.length + 1;

        for (int i = 0; i < scannedDocs.length; i++) {
          final path = scannedDocs[i];
          if (path is! String) continue;

          final file = File(path);
          if (!await file.exists()) continue;

          final length = await file.length();
          final mimeType = lookupMimeType(path) ?? 'image/jpeg';

          newPages.add(
            DocumentPageInfo(
              file: file,
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
  void setDocumentType(String? value) {
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

  /// Обновить теги
  void setTags(List<String> tagIds, List<String> tagNames) {
    state = state.copyWith(tagIds: tagIds, tagNames: tagNames);
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
      final dao = await ref.read(documentDaoProvider.future);
      final documentService = await ref.read(
        documentStorageServiceProvider.future,
      );

      if (state.isEditMode && state.editingDocumentId != null) {
        // Режим редактирования
        return await _updateDocument(dao, documentService);
      } else {
        // Режим создания
        return await _createDocument(documentService);
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

    logInfo('Document created: $documentId', tag: _logTag);
    state = state.copyWith(isSaving: false, isSaved: true);

    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityAdd(EntityType.document, entityId: documentId);

    return true;
  }

  /// Обновить существующий документ
  Future<bool> _updateDocument(
    DocumentDao dao,
    DocumentStorageService documentService,
  ) async {
    final documentId = state.editingDocumentId!;

    // Обновляем метаданные документа
    final dto = UpdateDocumentDto(
      title: state.title.trim(),
      documentType: state.documentType,
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
      categoryId: state.categoryId,
      tagsIds: state.tagIds,
    );

    final success = await dao.updateDocument(documentId, dto);

    if (!success) {
      logWarning('Failed to update document metadata', tag: _logTag);
      state = state.copyWith(isSaving: false);
      return false;
    }

    // Добавляем новые страницы если есть
    final newPages = state.pages
        .where((p) => p.isNew && p.file != null)
        .toList();

    if (newPages.isNotEmpty) {
      final pageFiles = newPages.map((p) => p.file!).toList();

      await documentService.addPagesToDocument(
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

    logInfo('Document updated: $documentId', tag: _logTag);
    state = state.copyWith(isSaving: false, isSaved: true);

    ref
        .read(dataRefreshTriggerProvider.notifier)
        .triggerEntityUpdate(EntityType.document, entityId: documentId);

    return true;
  }

  /// Сбросить флаг сохранения
  void resetSaved() {
    state = state.copyWith(isSaved: false);
  }
}
