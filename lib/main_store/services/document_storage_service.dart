import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/services/file_storage_service.dart';
import 'package:uuid/uuid.dart';

class DocumentStorageService {
  final MainStore _db;
  final FileStorageService _fileStorageService;

  DocumentStorageService(this._db, this._fileStorageService);

  /// Создать документ с несколькими страницами
  /// Возвращает ID созданного документа
  Future<String> createDocumentWithPages({
    required String title,
    String? documentType,
    String? description,
    String? categoryId,
    required List<String> tagsIds,
    required List<File> pageFiles,
    void Function(int current, int total)? onProgress,
  }) async {
    if (pageFiles.isEmpty) {
      throw Exception('Document must have at least one page');
    }

    return await _db.transaction(() async {
      // 1. Создаем документ
      final documentDto = CreateDocumentDto(
        title: title,
        documentType: documentType,
        description: description,
        pageCount: pageFiles.length,
        categoryId: categoryId,
        tagsIds: tagsIds,
      );

      final documentId = await _db.documentDao.createDocument(documentDto);

      // 2. Импортируем каждую страницу как файл и создаем запись DocumentPages
      for (int i = 0; i < pageFiles.length; i++) {
        final pageFile = pageFiles[i];
        final pageNumber = i + 1;
        final isPrimary = i == 0; // Первая страница - главная

        // Импортируем файл страницы
        final metadataId = await _fileStorageService.importPageFile(
          sourceFile: pageFile,
          onProgress: (processed, total) {
            onProgress?.call(i + 1, pageFiles.length);
          },
        );

        // Создаем запись страницы документа
        final pageId = const Uuid().v4();
        await _db
            .into(_db.documentPages)
            .insert(
              DocumentPagesCompanion.insert(
                id: Value(pageId),
                documentId: documentId,
                metadataId: Value(metadataId),
                pageNumber: pageNumber,
                isPrimary: Value(isPrimary),
              ),
            );

        logInfo(
          'Added page $pageNumber to document $documentId',
          tag: 'DocumentStorageService',
        );
      }

      logInfo(
        'Created document $documentId with ${pageFiles.length} pages',
        tag: 'DocumentStorageService',
      );

      return documentId;
    });
  }

  /// Добавить страницы к существующему документу
  Future<void> addPagesToDocument({
    required String documentId,
    required List<File> pageFiles,
    void Function(int current, int total)? onProgress,
  }) async {
    if (pageFiles.isEmpty) return;

    await _db.transaction(() async {
      // Получаем текущее количество страниц
      final existingPages =
          await (_db.select(_db.documentPages)
                ..where((p) => p.documentId.equals(documentId))
                ..orderBy([(p) => OrderingTerm.desc(p.pageNumber)]))
              .get();

      final startPageNumber = (existingPages.firstOrNull?.pageNumber ?? 0) + 1;

      // Добавляем новые страницы
      for (int i = 0; i < pageFiles.length; i++) {
        final pageFile = pageFiles[i];
        final pageNumber = startPageNumber + i;

        final document = await _db.documentDao.getDocumentById(documentId);
        if (document == null) {
          throw Exception('Document not found');
        }

        // Импортируем файл страницы
        final metadataId = await _fileStorageService.importPageFile(
          sourceFile: pageFile,
          onProgress: (processed, total) {
            onProgress?.call(i + 1, pageFiles.length);
          },
        );

        // Создаем запись страницы
        final pageId = const Uuid().v4();
        await _db
            .into(_db.documentPages)
            .insert(
              DocumentPagesCompanion.insert(
                id: Value(pageId),
                documentId: documentId,

                metadataId: Value(metadataId),
                pageNumber: pageNumber,
              ),
            );
      }

      // Обновляем количество страниц в документе
      final newPageCount = existingPages.length + pageFiles.length;
      await _db.documentDao.updateDocument(
        documentId,
        UpdateDocumentDto(pageCount: newPageCount),
      );

      logInfo(
        'Added ${pageFiles.length} pages to document $documentId',
        tag: 'DocumentStorageService',
      );
    });
  }

  /// Получить все страницы документа
  Future<List<DocumentPagesData>> getDocumentPages(String documentId) async {
    return await (_db.select(_db.documentPages)
          ..where((p) => p.documentId.equals(documentId))
          ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
        .get();
  }

  /// Получить главную страницу документа (обложку)
  Future<DocumentPagesData?> getPrimaryPage(String documentId) async {
    return await (_db.select(_db.documentPages)..where(
          (p) => p.documentId.equals(documentId) & p.isPrimary.equals(true),
        ))
        .getSingleOrNull();
  }

  /// Удалить страницу документа
  Future<bool> deleteDocumentPage(String pageId) async {
    return await _db.transaction(() async {
      // Получаем информацию о странице
      final page = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (page == null) return false;

      // Удаляем файл страницы с диска
      await _fileStorageService.deleteFileFromDisk(page.metadataId!);

      // Удаляем запись файла из БД
      await _db.fileDao.permanentDelete(page.metadataId!);

      // Удаляем запись страницы
      final result = await (_db.delete(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).go();

      if (result > 0) {
        // Обновляем количество страниц в документе
        final remainingPages = await (_db.select(
          _db.documentPages,
        )..where((p) => p.documentId.equals(page.documentId))).get();

        await _db.documentDao.updateDocument(
          page.documentId,
          UpdateDocumentDto(pageCount: remainingPages.length),
        );

        // Перенумеруем оставшиеся страницы
        await _renumberPages(page.documentId);

        logInfo(
          'Deleted page $pageId from document ${page.documentId}',
          tag: 'DocumentStorageService',
        );
      }

      return result > 0;
    });
  }

  /// Перенумеровать страницы документа
  Future<void> _renumberPages(String documentId) async {
    final pages =
        await (_db.select(_db.documentPages)
              ..where((p) => p.documentId.equals(documentId))
              ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
            .get();

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final newPageNumber = i + 1;

      if (page.pageNumber != newPageNumber) {
        await (_db.update(_db.documentPages)
              ..where((p) => p.id.equals(page.id)))
            .write(DocumentPagesCompanion(pageNumber: Value(newPageNumber)));
      }
    }
  }

  /// Установить главную страницу документа
  Future<bool> setPrimaryPage(String pageId) async {
    return await _db.transaction(() async {
      final page = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (page == null) return false;

      // Сбрасываем isPrimary у всех страниц документа
      await (_db.update(_db.documentPages)
            ..where((p) => p.documentId.equals(page.documentId)))
          .write(const DocumentPagesCompanion(isPrimary: Value(false)));

      // Устанавливаем isPrimary для выбранной страницы
      final result =
          await (_db.update(_db.documentPages)
                ..where((p) => p.id.equals(pageId)))
              .write(const DocumentPagesCompanion(isPrimary: Value(true)));

      return result > 0;
    });
  }

  /// Удалить документ со всеми страницами
  Future<bool> deleteDocumentWithPages(String documentId) async {
    return await _db.transaction(() async {
      // Получаем все страницы документа
      final pages = await getDocumentPages(documentId);

      // Удаляем каждую страницу (файлы и записи)
      for (final page in pages) {
        await _fileStorageService.deleteFileFromDisk(page.metadataId!);
        await _db.fileDao.permanentDelete(page.metadataId!);
      }

      // Удаляем все записи страниц
      await (_db.delete(
        _db.documentPages,
      )..where((p) => p.documentId.equals(documentId))).go();

      // Удаляем документ
      final result = await _db.documentDao.permanentDelete(documentId);

      if (result) {
        logInfo(
          'Deleted document $documentId with ${pages.length} pages',
          tag: 'DocumentStorageService',
        );
      }

      return result;
    });
  }

  /// Расшифровать страницу документа
  Future<String> decryptDocumentPage({
    required String pageId,
    void Function(int, int)? onProgress,
  }) async {
    final page = await (_db.select(
      _db.documentPages,
    )..where((p) => p.id.equals(pageId))).getSingleOrNull();

    if (page == null) {
      throw Exception('Document page not found');
    }

    return await _fileStorageService.decryptPageFile(
      metadataId: page.metadataId!,
      onProgress: onProgress,
    );
  }

  /// Обновить содержимое страницы документа
  Future<void> updateDocumentPage({
    required String pageId,
    required File newPageFile,
    void Function(int, int)? onProgress,
  }) async {
    await _db.transaction(() async {
      final page = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (page == null) {
        throw Exception('Document page not found');
      }

      // Обновляем содержимое файла страницы
      await _fileStorageService.updateFileContent(
        fileId: page.metadataId!,
        newFile: newPageFile,
        onProgress: onProgress,
      );

      // Обновляем дату изменения страницы
      await (_db.update(_db.documentPages)..where((p) => p.id.equals(pageId)))
          .write(DocumentPagesCompanion(modifiedAt: Value(DateTime.now())));

      logInfo('Updated page $pageId content', tag: 'DocumentStorageService');
    });
  }

  /// Переместить страницу (изменить pageNumber)
  Future<bool> moveDocumentPage({
    required String pageId,
    required int newPageNumber,
  }) async {
    return await _db.transaction(() async {
      final page = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (page == null) return false;

      final allPages =
          await (_db.select(_db.documentPages)
                ..where((p) => p.documentId.equals(page.documentId))
                ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
              .get();

      if (newPageNumber < 1 || newPageNumber > allPages.length) {
        return false;
      }

      // Удаляем страницу из текущей позиции
      final updatedPages = allPages.where((p) => p.id != pageId).toList();

      // Вставляем на новую позицию
      updatedPages.insert(newPageNumber - 1, page);

      // Перенумеруем все страницы
      for (int i = 0; i < updatedPages.length; i++) {
        await (_db.update(_db.documentPages)
              ..where((p) => p.id.equals(updatedPages[i].id)))
            .write(DocumentPagesCompanion(pageNumber: Value(i + 1)));
      }

      logInfo(
        'Moved page $pageId to position $newPageNumber',
        tag: 'DocumentStorageService',
      );

      return true;
    });
  }

  /// Получить количество страниц в документе
  Future<int> getDocumentPageCount(String documentId) async {
    final query = _db.selectOnly(_db.documentPages)
      ..addColumns([_db.documentPages.id.count()])
      ..where(_db.documentPages.documentId.equals(documentId));

    final result = await query.getSingle();
    return result.read(_db.documentPages.id.count()) ?? 0;
  }
}
