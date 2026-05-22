import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/vault_db/core/models/dto/document_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/document_version_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/item_link_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/vault_item_base_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/services/document_versions/document_version_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/base_vault_entity_service.dart';
import 'package:hoplixi/vault_db/core/services/entities/document_service.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_history_service_assembly.dart';
import 'package:hoplixi/vault_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_items_state_service.dart';
import 'package:hoplixi/vault_db/core/tables/tables.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/services/other/file_storage_service.dart';
import 'package:uuid/uuid.dart';

/// Класс-совместимости с UI для отображения страниц документа.
/// Позволяет UI-слою прозрачно обращаться к полям страницы без изменений.
class DocumentPageCompat {
  final String id;
  final String documentId;
  final String? metadataId;
  final int pageNumber;
  final bool isPrimary;

  DocumentPageCompat({
    required this.id,
    required this.documentId,
    this.metadataId,
    required this.pageNumber,
    required this.isPrimary,
  });
}

class DocumentStorageService {
  final VaultDB _db;
  final FileStorageService _fileStorageService;
  late final DocumentService _documentService;
  late final DocumentVersionService _documentVersionService;
  late final VaultItemRelationsService _relationsService;

  DocumentStorageService(this._db, this._fileStorageService) {
    _documentVersionService = DocumentVersionService(db: _db);
    _relationsService = VaultItemRelationsService(db: _db);

    final historyAssembly = VaultHistoryServiceAssembly(_db);
    final historyService = historyAssembly.historyService;
    final viewResolver = historyAssembly.viewResolver;

    final vaultItemsStateService = VaultItemsStateService(
      db: _db,
      viewResolver: viewResolver,
      historyService: historyService,
    );

    final deps = VaultEntityServiceDeps(
      db: _db,
      repositories: VaultRepositories(_db),
      relationsService: _relationsService,
      historyService: historyService,
      vaultItemsStateService: vaultItemsStateService,
    );

    _documentService = DocumentService(
      deps: deps,
      repository: deps.repositories.document,
    );
  }

  /// Создать документ с несколькими страницами
  /// Возвращает ID созданного документа
  Future<String> createDocumentWithPages({
    required String title,
    String? documentType,
    String? description,
    String? categoryId,
    String? noteId,
    required List<String> tagsIds,
    required List<File> pageFiles,
    void Function(int current, int total)? onProgress,
  }) async {
    if (pageFiles.isEmpty) {
      throw Exception('Document must have at least one page');
    }

    return await _db.transaction(() async {
      // 1. Создаем документ через DocumentService
      final createDocumentDto = CreateDocumentDto(
        item: VaultItemCreateDto(
          name: title,
          description: description,
          categoryId: categoryId,
        ),
        tagIds: tagsIds,
      );

      final documentIdResult = await _documentService.create(createDocumentDto);
      final documentId = documentIdResult.getOrThrow();

      // 2. Создаем связь с заметкой, если передана
      if (noteId != null && noteId.isNotEmpty) {
        final linkDto = CreateItemLinkDto(
          sourceItemId: documentId,
          targetItemId: noteId,
          relationType: ItemLinkType.note,
        );
        final linkRes = await _relationsService.createLink(linkDto);
        if (linkRes.isError()) {
          throw linkRes.exceptionOrNull()!;
        }
      }

      // 3. Импортируем файлы страниц и создаем их snapshots в истории
      final versionPages = <CreateDocumentVersionPageDto>[];
      for (int i = 0; i < pageFiles.length; i++) {
        final pageFile = pageFiles[i];
        final pageNumber = i + 1;
        final isPrimary = i == 0; // Первая страница - главная

        // Шифруем и загружаем файл на диск
        final metadataId = await _fileStorageService.importPageFile(
          sourceFile: pageFile,
          onProgress: (_) => onProgress?.call(i + 1, pageFiles.length),
        );

        // Получаем загруженные метаданные файла для сохранения истории
        final metadata = await (_db.select(
          _db.fileMetadata,
        )..where((m) => m.id.equals(metadataId))).getSingle();

        // Генерируем UUID для страницы версии и записи истории метаданных заранее
        final versionPageId = const Uuid().v4();
        final metadataHistoryId = const Uuid().v4();

        // Записываем snapshot в file_metadata_history с указанием правильного owner_id
        await _db
            .into(_db.fileMetadataHistory)
            .insert(
              FileMetadataHistoryCompanion.insert(
                id: Value(metadataHistoryId),
                ownerKind: const Value(
                  FileMetadataHistoryOwnerKind.documentVersionPage,
                ),
                ownerId: Value(versionPageId),
                metadataId: Value(metadataId),
                fileName: metadata.fileName,
                fileExtension: Value(metadata.fileExtension),
                filePath: Value(metadata.filePath),
                mimeType: metadata.mimeType,
                fileSize: metadata.fileSize,
                sha256: Value(metadata.sha256),
              ),
            );

        // Добавляем DTO страницы в список новой версии
        versionPages.add(
          CreateDocumentVersionPageDto(
            id: versionPageId,
            metadataHistoryId: metadataHistoryId,
            pageNumber: pageNumber,
            pageSha256Hash: metadata.sha256,
            isPrimary: isPrimary,
          ),
        );

        logInfo(
          'Added page $pageNumber snapshot (metadataId: $metadataId) for document $documentId',
          tag: 'DocumentStorageService',
        );
      }

      // 4. Создаем и активируем первую версию документа
      DocumentType? docTypeEnum;
      if (documentType != null) {
        docTypeEnum = DocumentType.values.firstWhere(
          (e) => e.name == documentType,
          orElse: () => DocumentType.other,
        );
      }

      final createVersionDto = CreateDocumentVersionDto(
        documentId: documentId,
        pages: versionPages,
        documentType: docTypeEnum,
        documentTypeOther: docTypeEnum == DocumentType.other
            ? documentType
            : null,
      );

      final versionResult = await _documentVersionService.createVersion(
        createVersionDto,
      );
      if (versionResult.isError()) {
        throw versionResult.exceptionOrNull()!;
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
      // 1. Получаем текущую активную версию документа
      final currentVersionRes = await _documentVersionService.getCurrentVersion(
        documentId: documentId,
      );
      final currentVersion = currentVersionRes.getOrThrow();

      // 2. Сортируем существующие страницы и находим максимальный номер
      final existingPages = currentVersion.pages.toList()
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      final startPageNumber = (existingPages.lastOrNull?.pageNumber ?? 0) + 1;

      // 3. Формируем список страниц для новой версии
      final newVersionPages = <CreateDocumentVersionPageDto>[];

      // Добавляем существующие страницы
      for (final oldPage in existingPages) {
        newVersionPages.add(
          CreateDocumentVersionPageDto(
            pageId: oldPage.pageId,
            metadataHistoryId: oldPage.metadataHistoryId,
            pageNumber: oldPage.pageNumber,
            pageSha256Hash: oldPage.pageSha256Hash,
            isPrimary: oldPage.isPrimary,
          ),
        );
      }

      // Импортируем и добавляем новые файлы страниц
      for (int i = 0; i < pageFiles.length; i++) {
        final pageFile = pageFiles[i];
        final pageNumber = startPageNumber + i;

        // Шифруем и сохраняем новый файл
        final metadataId = await _fileStorageService.importPageFile(
          sourceFile: pageFile,
          onProgress: (_) => onProgress?.call(i + 1, pageFiles.length),
        );

        final metadata = await (_db.select(
          _db.fileMetadata,
        )..where((m) => m.id.equals(metadataId))).getSingle();

        final versionPageId = const Uuid().v4();
        final metadataHistoryId = const Uuid().v4();

        // Записываем snapshot в file_metadata_history
        await _db
            .into(_db.fileMetadataHistory)
            .insert(
              FileMetadataHistoryCompanion.insert(
                id: Value(metadataHistoryId),
                ownerKind: const Value(
                  FileMetadataHistoryOwnerKind.documentVersionPage,
                ),
                ownerId: Value(versionPageId),
                metadataId: Value(metadataId),
                fileName: metadata.fileName,
                fileExtension: Value(metadata.fileExtension),
                filePath: Value(metadata.filePath),
                mimeType: metadata.mimeType,
                fileSize: metadata.fileSize,
                sha256: Value(metadata.sha256),
              ),
            );

        newVersionPages.add(
          CreateDocumentVersionPageDto(
            id: versionPageId,
            pageId: null, // Новая live-страница
            metadataHistoryId: metadataHistoryId,
            pageNumber: pageNumber,
            pageSha256Hash: metadata.sha256,
            isPrimary: false,
          ),
        );
      }

      // 4. Создаем новую версию документа
      final createVersionDto = CreateDocumentVersionDto(
        documentId: documentId,
        pages: newVersionPages,
        documentType: currentVersion.documentType,
        documentTypeOther: currentVersion.documentTypeOther,
      );

      final versionResult = await _documentVersionService.createVersion(
        createVersionDto,
      );
      if (versionResult.isError()) {
        throw versionResult.exceptionOrNull()!;
      }

      logInfo(
        'Added ${pageFiles.length} pages to document $documentId (total pages: ${newVersionPages.length})',
        tag: 'DocumentStorageService',
      );
    });
  }

  /// Получить все страницы документа (совместимо с UI)
  Future<List<DocumentPageCompat>> getDocumentPages(String documentId) async {
    final currentVersionRes = await _documentVersionService.getCurrentVersion(
      documentId: documentId,
    );
    if (currentVersionRes.isError()) {
      return const [];
    }
    final currentVersion = currentVersionRes.getOrThrow();

    final result = <DocumentPageCompat>[];
    for (final page in currentVersion.pages) {
      String? metadataId;
      if (page.metadataHistoryId != null) {
        final historyRecord =
            await (_db.select(_db.fileMetadataHistory)
                  ..where((h) => h.id.equals(page.metadataHistoryId!)))
                .getSingleOrNull();
        metadataId = historyRecord?.metadataId;
      }

      result.add(
        DocumentPageCompat(
          id: page.pageId,
          documentId: documentId,
          metadataId: metadataId,
          pageNumber: page.pageNumber,
          isPrimary: page.isPrimary,
        ),
      );
    }

    result.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return result;
  }

  /// Получить главную страницу документа (обложку)
  Future<DocumentPageCompat?> getPrimaryPage(String documentId) async {
    final pages = await getDocumentPages(documentId);
    if (pages.isEmpty) return null;
    return pages.firstWhere((p) => p.isPrimary, orElse: () => pages.first);
  }

  /// Удалить страницу документа
  Future<bool> deleteDocumentPage(String pageId) async {
    return await _db.transaction(() async {
      // 1. Находим стабильную страницу по pageId, чтобы узнать documentId
      final pageRecord = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (pageRecord == null) return false;
      final documentId = pageRecord.documentId;

      // 2. Получаем текущую активную версию
      final currentVersionRes = await _documentVersionService.getCurrentVersion(
        documentId: documentId,
      );
      final currentVersion = currentVersionRes.getOrThrow();

      // 3. Фильтруем список страниц, удаляя нужную
      final remainingPages =
          currentVersion.pages.where((p) => p.pageId != pageId).toList()
            ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      if (remainingPages.isEmpty) {
        throw Exception('Cannot delete the last page of a document');
      }

      // Переназначаем isPrimary, если удалили главную
      bool hasPrimary = remainingPages.any((p) => p.isPrimary);

      // 4. Формируем список для новой версии с пересчитанными номерами
      final newVersionPages = <CreateDocumentVersionPageDto>[];
      for (int i = 0; i < remainingPages.length; i++) {
        final oldPage = remainingPages[i];
        final isPrimary = !hasPrimary && i == 0 ? true : oldPage.isPrimary;
        newVersionPages.add(
          CreateDocumentVersionPageDto(
            pageId: oldPage.pageId,
            metadataHistoryId: oldPage.metadataHistoryId,
            pageNumber: i + 1,
            pageSha256Hash: oldPage.pageSha256Hash,
            isPrimary: isPrimary,
          ),
        );
      }

      // 5. Создаем новую версию документа
      final createVersionDto = CreateDocumentVersionDto(
        documentId: documentId,
        pages: newVersionPages,
        documentType: currentVersion.documentType,
        documentTypeOther: currentVersion.documentTypeOther,
      );

      final versionResult = await _documentVersionService.createVersion(
        createVersionDto,
      );
      if (versionResult.isError()) {
        throw versionResult.exceptionOrNull()!;
      }

      logInfo(
        'Deleted page $pageId from document $documentId',
        tag: 'DocumentStorageService',
      );

      return true;
    });
  }

  /// Установить главную страницу документа
  Future<bool> setPrimaryPage(String pageId) async {
    return await _db.transaction(() async {
      // 1. Находим стабильную страницу по pageId, чтобы узнать documentId
      final pageRecord = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (pageRecord == null) return false;
      final documentId = pageRecord.documentId;

      // 2. Получаем текущую версию
      final currentVersionRes = await _documentVersionService.getCurrentVersion(
        documentId: documentId,
      );
      final currentVersion = currentVersionRes.getOrThrow();

      // 3. Формируем список страниц с измененным isPrimary
      final newVersionPages = <CreateDocumentVersionPageDto>[];
      for (final oldPage in currentVersion.pages) {
        newVersionPages.add(
          CreateDocumentVersionPageDto(
            pageId: oldPage.pageId,
            metadataHistoryId: oldPage.metadataHistoryId,
            pageNumber: oldPage.pageNumber,
            pageSha256Hash: oldPage.pageSha256Hash,
            isPrimary: oldPage.pageId == pageId,
          ),
        );
      }

      // 4. Создаем новую версию
      final createVersionDto = CreateDocumentVersionDto(
        documentId: documentId,
        pages: newVersionPages,
        documentType: currentVersion.documentType,
        documentTypeOther: currentVersion.documentTypeOther,
      );

      final versionResult = await _documentVersionService.createVersion(
        createVersionDto,
      );
      if (versionResult.isError()) {
        throw versionResult.exceptionOrNull()!;
      }

      return true;
    });
  }

  /// Удалить документ со всеми страницами (мягкое удаление)
  Future<bool> deleteDocumentWithPages(String documentId) async {
    final res = await _documentService.softDelete(documentId);
    if (res.isSuccess()) {
      logInfo(
        'Soft deleted document $documentId',
        tag: 'DocumentStorageService',
      );
      return true;
    }
    return false;
  }

  /// Расшифровать страницу документа
  Future<String> decryptDocumentPage({
    required String pageId,
    void Function(double percentage)? onProgress,
  }) async {
    // 1. Находим стабильную страницу по pageId, чтобы узнать documentId
    final pageRecord = await (_db.select(
      _db.documentPages,
    )..where((p) => p.id.equals(pageId))).getSingleOrNull();

    if (pageRecord == null) {
      throw Exception('Document page not found');
    }
    final documentId = pageRecord.documentId;

    // 2. Получаем текущую активную версию
    final currentVersionRes = await _documentVersionService.getCurrentVersion(
      documentId: documentId,
    );
    final currentVersion = currentVersionRes.getOrThrow();

    // 3. Находим страницу версии
    final page = currentVersion.pages.firstWhere(
      (p) => p.pageId == pageId,
      orElse: () => throw Exception('Page not found in active version'),
    );

    if (page.metadataHistoryId == null) {
      throw Exception('Page has no metadata history');
    }

    // 4. Получаем оригинальный metadataId из истории метаданных
    final historyRecord = await (_db.select(
      _db.fileMetadataHistory,
    )..where((h) => h.id.equals(page.metadataHistoryId!))).getSingleOrNull();

    if (historyRecord == null || historyRecord.metadataId == null) {
      throw Exception('File metadata history not found or has no metadataId');
    }

    // 5. Расшифровываем файл по оригинальному metadataId
    return await _fileStorageService.decryptPageFile(
      metadataId: historyRecord.metadataId!,
      onProgress: onProgress,
    );
  }

  /// Обновить содержимое страницы документа (создает новую версию)
  Future<void> updateDocumentPage({
    required String pageId,
    required File newPageFile,
    void Function(double percentage)? onProgress,
  }) async {
    await _db.transaction(() async {
      // 1. Находим стабильную страницу по pageId, чтобы узнать documentId
      final pageRecord = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (pageRecord == null) {
        throw Exception('Document page not found');
      }
      final documentId = pageRecord.documentId;

      // 2. Получаем текущую версию
      final currentVersionRes = await _documentVersionService.getCurrentVersion(
        documentId: documentId,
      );
      final currentVersion = currentVersionRes.getOrThrow();

      // 3. Загружаем и шифруем новый файл на диске
      final metadataId = await _fileStorageService.importPageFile(
        sourceFile: newPageFile,
        onProgress: onProgress,
      );

      final metadata = await (_db.select(
        _db.fileMetadata,
      )..where((m) => m.id.equals(metadataId))).getSingle();

      // 4. Формируем страницы для новой версии
      final newVersionPages = <CreateDocumentVersionPageDto>[];
      for (final oldPage in currentVersion.pages) {
        if (oldPage.pageId == pageId) {
          final versionPageId = const Uuid().v4();
          final metadataHistoryId = const Uuid().v4();

          // Записываем новый snapshot в file_metadata_history
          await _db
              .into(_db.fileMetadataHistory)
              .insert(
                FileMetadataHistoryCompanion.insert(
                  id: Value(metadataHistoryId),
                  ownerKind: const Value(
                    FileMetadataHistoryOwnerKind.documentVersionPage,
                  ),
                  ownerId: Value(versionPageId),
                  metadataId: Value(metadataId),
                  fileName: metadata.fileName,
                  fileExtension: Value(metadata.fileExtension),
                  filePath: Value(metadata.filePath),
                  mimeType: metadata.mimeType,
                  fileSize: metadata.fileSize,
                  sha256: Value(metadata.sha256),
                ),
              );

          newVersionPages.add(
            CreateDocumentVersionPageDto(
              id: versionPageId,
              pageId: oldPage.pageId,
              metadataHistoryId: metadataHistoryId,
              pageNumber: oldPage.pageNumber,
              pageSha256Hash: metadata.sha256,
              isPrimary: oldPage.isPrimary,
            ),
          );
        } else {
          newVersionPages.add(
            CreateDocumentVersionPageDto(
              pageId: oldPage.pageId,
              metadataHistoryId: oldPage.metadataHistoryId,
              pageNumber: oldPage.pageNumber,
              pageSha256Hash: oldPage.pageSha256Hash,
              isPrimary: oldPage.isPrimary,
            ),
          );
        }
      }

      // 5. Создаем новую версию
      final createVersionDto = CreateDocumentVersionDto(
        documentId: documentId,
        pages: newVersionPages,
        documentType: currentVersion.documentType,
        documentTypeOther: currentVersion.documentTypeOther,
      );

      final versionResult = await _documentVersionService.createVersion(
        createVersionDto,
      );
      if (versionResult.isError()) {
        throw versionResult.exceptionOrNull()!;
      }

      logInfo(
        'Updated page $pageId content in document $documentId',
        tag: 'DocumentStorageService',
      );
    });
  }

  /// Переместить страницу (изменить pageNumber и создать новую версию)
  Future<bool> moveDocumentPage({
    required String pageId,
    required int newPageNumber,
  }) async {
    return await _db.transaction(() async {
      // 1. Находим стабильную страницу по pageId, чтобы узнать documentId
      final pageRecord = await (_db.select(
        _db.documentPages,
      )..where((p) => p.id.equals(pageId))).getSingleOrNull();

      if (pageRecord == null) return false;
      final documentId = pageRecord.documentId;

      // 2. Получаем текущую активную версию
      final currentVersionRes = await _documentVersionService.getCurrentVersion(
        documentId: documentId,
      );
      final currentVersion = currentVersionRes.getOrThrow();

      final allPages = currentVersion.pages.toList()
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      if (newPageNumber < 1 || newPageNumber > allPages.length) {
        return false;
      }

      final pageToMove = allPages.firstWhere(
        (p) => p.pageId == pageId,
        orElse: () => throw Exception('Page not found'),
      );

      // Удаляем из текущей позиции
      final updatedPages = allPages.where((p) => p.pageId != pageId).toList();

      // Вставляем на новую позицию
      updatedPages.insert(newPageNumber - 1, pageToMove);

      // 3. Формируем страницы для новой версии с обновленными номерами
      final newVersionPages = <CreateDocumentVersionPageDto>[];
      for (int i = 0; i < updatedPages.length; i++) {
        final oldPage = updatedPages[i];
        newVersionPages.add(
          CreateDocumentVersionPageDto(
            pageId: oldPage.pageId,
            metadataHistoryId: oldPage.metadataHistoryId,
            pageNumber: i + 1,
            pageSha256Hash: oldPage.pageSha256Hash,
            isPrimary: oldPage.isPrimary,
          ),
        );
      }

      // 4. Создаем новую версию
      final createVersionDto = CreateDocumentVersionDto(
        documentId: documentId,
        pages: newVersionPages,
        documentType: currentVersion.documentType,
        documentTypeOther: currentVersion.documentTypeOther,
      );

      final versionResult = await _documentVersionService.createVersion(
        createVersionDto,
      );
      if (versionResult.isError()) {
        throw versionResult.exceptionOrNull()!;
      }

      logInfo(
        'Moved page $pageId to position $newPageNumber in document $documentId',
        tag: 'DocumentStorageService',
      );

      return true;
    });
  }

  /// Получить количество страниц в документе
  Future<int> getDocumentPageCount(String documentId) async {
    final currentVersionRes = await _documentVersionService.getCurrentVersion(
      documentId: documentId,
    );
    if (currentVersionRes.isError()) {
      return 0;
    }
    return currentVersionRes.getOrThrow().pages.length;
  }
}
