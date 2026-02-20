import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_crypto/file_crypto.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/dto/file_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/store_settings_keys.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileStorageService {
  final MainStore _db;
  final ArchiveEncryptor _encryptor;
  final String _attachmentsPath;
  final String _decryptedAttachmentsPath;

  FileStorageService(
    this._db,
    this._attachmentsPath,
    this._decryptedAttachmentsPath,
  ) : _encryptor = ArchiveEncryptor();

  /// Получить ключ шифрования из метаданных хранилища
  Future<String> _getAttachmentKey() async {
    final meta = await _db.select(_db.storeMetaTable).getSingle();
    return meta.attachmentKey;
  }

  /// Получить путь к директории вложений
  Future<String> _getAttachmentsPath() async {
    final directory = Directory(_attachmentsPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return _attachmentsPath;
  }

  /// Импортировать файл: шифрует и сохраняет в БД
  Future<String> importFile({
    required File sourceFile,
    required String name,
    String? description,
    String? categoryId,
    String? noteId,
    required List<String> tagsIds,
    void Function(int, int)? onProgress,
  }) async {
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final filePathUuid = const Uuid().v4();
    final extension = p.extension(sourceFile.path);
    final encryptedFileName =
        '$filePathUuid${MainConstants.encryptedFileExtension}';
    final encryptedFilePath = p.join(attachmentsPath, encryptedFileName);

    // Шифруем файл
    await _encryptor.encrypt(
      inputPath: sourceFile.path,
      outputPath: encryptedFilePath,
      password: key,
      onProgress: onProgress,
    );

    // Вычисляем хеш оригинального файла
    final digest = await sha256.bind(sourceFile.openRead()).first;
    final fileHash = digest.toString();

    final fileSize = await sourceFile.length();
    final fileName = p.basename(sourceFile.path);

    final mimeType =
        lookupMimeType(sourceFile.path) ?? 'application/octet-stream';

    final dto = CreateFileDto(
      name: name,
      fileName: fileName,
      fileExtension: extension,
      filePath: encryptedFileName,
      mimeType: mimeType,
      fileSize: fileSize,
      fileHash: fileHash,
      description: description,
      categoryId: categoryId,
      noteId: noteId,
      tagsIds: tagsIds,
    );

    return _db.fileDao.createFile(dto);
  }

  /// Расшифровать файл в указанный путь
  Future<String> decryptFile({
    required String fileId,
    void Function(int, int)? onProgress,
  }) async {
    final record = await _db.fileDao.getById(fileId);
    if (record == null) {
      throw Exception('File not found in database');
    }
    final (_, fileItem) = record;

    if (fileItem.metadataId == null) {
      throw Exception('File has no metadata');
    }

    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(fileItem.metadataId!))).getSingleOrNull();

    if (metadata == null) {
      throw Exception('File metadata not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath);

    logDebug('Decrypting file: $encryptedFilePath');

    if (!await File(encryptedFilePath).exists()) {
      throw Exception('Encrypted file not found on disk');
    }

    // Создаем временную директорию для расшифровки, так как ArchiveEncryptor
    // восстанавливает оригинальное имя файла, а нам нужно сохранить в destinationPath
    final tempDir = await Directory.systemTemp.createTemp('hoplixi_decrypt_');
    try {
      final result = await _encryptor.decrypt(
        inputPath: encryptedFilePath,
        outputPath: tempDir.path,
        password: key,
        onProgress: onProgress,
      );

      final decryptedFile = File(result.outputPath);
      if (await decryptedFile.exists()) {
        // Копируем файл в целевой путь
        // Убедимся, что директория назначения существует
        final destDir = Directory(_decryptedAttachmentsPath);
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }
        final destinationPath = p.join(
          _decryptedAttachmentsPath,
          p.basename(decryptedFile.path),
        );
        await decryptedFile.copy(destinationPath);
        return destinationPath;
      } else {
        throw Exception(
          'Decryption finished but file not found at ${result.outputPath}',
        );
      }
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Обновить содержимое файла: старый файл в историю, новый шифруется и сохраняется
  Future<void> updateFileContent({
    required String fileId,
    required File newFile,
    void Function(int, int)? onProgress,
  }) async {
    final record = await _db.fileDao.getById(fileId);
    if (record == null) throw Exception('File not found');
    final (currentVault, currentFileItem) = record;

    if (currentFileItem.metadataId == null) {
      throw Exception('File has no metadata');
    }

    final currentMetadata =
        await (_db.select(_db.fileMetadata)
              ..where((m) => m.id.equals(currentFileItem.metadataId!)))
            .getSingleOrNull();

    if (currentMetadata == null) {
      throw Exception('File metadata not found');
    }

    // Читаем настройку истории
    final historyEnabledStr =
        await (_db.select(_db.storeSettings)
              ..where((s) => s.key.equals(StoreSettingsKeys.historyEnabled)))
            .getSingleOrNull();
    final isHistoryEnabled =
        historyEnabledStr == null || historyEnabledStr.value == 'true';

    final attachmentsPath = await _getAttachmentsPath();

    if (isHistoryEnabled) {
      // 1. Создаем запись в истории
      String? categoryName;
      if (currentVault.categoryId != null) {
        final cat = await _db.categoryDao.getCategoryById(
          currentVault.categoryId!,
        );
        categoryName = cat?.name;
      }

      final historyDto = CreateFileHistoryDto(
        originalFileId: currentVault.id,
        action: ActionInHistory.modified.value,
        metadataId: currentFileItem.metadataId!,
        name: currentVault.name,
        description: currentVault.description,
        categoryName: categoryName,
        usedCount: currentVault.usedCount,
        isFavorite: currentVault.isFavorite,
        isArchived: currentVault.isArchived,
        isPinned: currentVault.isPinned,
        isDeleted: currentVault.isDeleted,
        originalCreatedAt: currentVault.createdAt,
        originalModifiedAt: currentVault.modifiedAt,
        originalLastAccessedAt: currentVault.lastUsedAt,
      );
      await _db.fileHistoryDao.createFileHistory(historyDto);
    }

    // 2. Шифруем новый файл
    final key = await _getAttachmentKey();
    final newFilePathUuid = const Uuid().v4();
    final newEncryptedFileName =
        '$newFilePathUuid${MainConstants.encryptedFileExtension}';
    final newEncryptedFilePath = p.join(attachmentsPath, newEncryptedFileName);

    await _encryptor.encrypt(
      inputPath: newFile.path,
      outputPath: newEncryptedFilePath,
      password: key,
      onProgress: onProgress,
    );

    // 3. Вычисляем новые метаданные
    final digest = await sha256.bind(newFile.openRead()).first;
    final newFileHash = digest.toString();
    final newFileSize = await newFile.length();
    final newFileName = p.basename(newFile.path);
    final newFileExtension = p.extension(newFile.path);
    final newMimeType =
        lookupMimeType(newFile.path) ?? 'application/octet-stream';

    // 4. Создаём новую запись FileMetadata
    final newMetadataId = const Uuid().v4();
    await _db
        .into(_db.fileMetadata)
        .insert(
          FileMetadataCompanion.insert(
            id: Value(newMetadataId),
            fileName: newFileName,
            fileExtension: newFileExtension,
            filePath: Value(newEncryptedFileName),
            mimeType: newMimeType,
            fileSize: newFileSize,
            fileHash: Value(newFileHash),
          ),
        );

    // 5. Обновляем запись в таблице FileItems
    await (_db.update(_db.fileItems)..where((f) => f.itemId.equals(fileId)))
        .write(FileItemsCompanion(metadataId: Value(newMetadataId)));

    if (!isHistoryEnabled) {
      // 6. История выключена - удаляем старый физический файл и старые метаданные
      final oldEncryptedFilePath = p.join(
        attachmentsPath,
        currentMetadata.filePath,
      );
      final oldFile = File(oldEncryptedFilePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      await (_db.delete(
        _db.fileMetadata,
      )..where((m) => m.id.equals(currentFileItem.metadataId!))).go();
    }
  }

  /// Импортировать файл страницы (только метаданные)
  Future<String> importPageFile({
    required File sourceFile,
    void Function(int, int)? onProgress,
  }) async {
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final filePathUuid = const Uuid().v4();
    final extension = p.extension(sourceFile.path);
    final encryptedFileName =
        '$filePathUuid${MainConstants.encryptedFileExtension}';
    final encryptedFilePath = p.join(attachmentsPath, encryptedFileName);

    await _encryptor.encrypt(
      inputPath: sourceFile.path,
      outputPath: encryptedFilePath,
      password: key,
      onProgress: onProgress,
    );

    final digest = await sha256.bind(sourceFile.openRead()).first;
    final fileHash = digest.toString();
    final fileSize = await sourceFile.length();
    final fileName = p.basename(sourceFile.path);
    final mimeType =
        lookupMimeType(sourceFile.path) ?? 'application/octet-stream';

    final metadataId = const Uuid().v4();
    await _db
        .into(_db.fileMetadata)
        .insert(
          FileMetadataCompanion.insert(
            id: Value(metadataId),
            fileName: fileName,
            fileExtension: extension,
            filePath: Value(encryptedFileName),
            mimeType: mimeType,
            fileSize: fileSize,
            fileHash: Value(fileHash),
          ),
        );

    return metadataId;
  }

  /// Расшифровать файл страницы по metadataId
  Future<String> decryptPageFile({
    required String metadataId,
    void Function(int, int)? onProgress,
  }) async {
    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).getSingleOrNull();

    if (metadata == null) {
      throw Exception('File metadata not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath);

    logDebug('Decrypting page file: $encryptedFilePath');

    if (!await File(encryptedFilePath).exists()) {
      throw Exception('Encrypted file not found on disk');
    }

    final tempDir = await Directory.systemTemp.createTemp('hoplixi_decrypt_');
    try {
      final result = await _encryptor.decrypt(
        inputPath: encryptedFilePath,
        outputPath: tempDir.path,
        password: key,
        onProgress: onProgress,
      );

      final decryptedFile = File(result.outputPath);
      if (await decryptedFile.exists()) {
        final destDir = Directory(_decryptedAttachmentsPath);
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }
        final destinationPath = p.join(
          _decryptedAttachmentsPath,
          p.basename(decryptedFile.path),
        );
        await decryptedFile.copy(destinationPath);
        return destinationPath;
      } else {
        throw Exception(
          'Decryption finished but file not found at ${result.outputPath}',
        );
      }
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Обновить содержимое файла страницы (обновляет метаданные)
  Future<void> updatePageFile({
    required String metadataId,
    required File newFile,
    void Function(int, int)? onProgress,
  }) async {
    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).getSingleOrNull();

    if (metadata == null) throw Exception('File metadata not found');

    // Удаляем старый файл с диска
    final attachmentsPath = await _getAttachmentsPath();
    final oldEncryptedFilePath = p.join(attachmentsPath, metadata.filePath);
    final oldFile = File(oldEncryptedFilePath);
    if (await oldFile.exists()) {
      await oldFile.delete();
    }

    // Шифруем новый файл
    final key = await _getAttachmentKey();
    final newFilePathUuid = const Uuid().v4();
    final newEncryptedFileName =
        '$newFilePathUuid${MainConstants.encryptedFileExtension}';
    final newEncryptedFilePath = p.join(attachmentsPath, newEncryptedFileName);

    await _encryptor.encrypt(
      inputPath: newFile.path,
      outputPath: newEncryptedFilePath,
      password: key,
      onProgress: onProgress,
    );

    // Вычисляем новые метаданные
    final digest = await sha256.bind(newFile.openRead()).first;
    final newFileHash = digest.toString();
    final newFileSize = await newFile.length();
    final newFileName = p.basename(newFile.path);
    final newFileExtension = p.extension(newFile.path);
    final newMimeType =
        lookupMimeType(newFile.path) ?? 'application/octet-stream';

    await (_db.update(
      _db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).write(
      FileMetadataCompanion(
        fileName: Value(newFileName),
        fileExtension: Value(newFileExtension),
        filePath: Value(newEncryptedFileName),
        mimeType: Value(newMimeType),
        fileSize: Value(newFileSize),
        fileHash: Value(newFileHash),
      ),
    );
  }

  /// Удалить файл страницы с диска по metadataId + удаление записи
  Future<bool> deletePageFile(String metadataId) async {
    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).getSingleOrNull();

    if (metadata == null) return false;

    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath);
    final file = File(encryptedFilePath);

    if (await file.exists()) {
      await file.delete();
    }

    await (_db.delete(
      _db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).go();

    return true;
  }

  /// Удалить файл с диска (используется при удалении из БД)
  Future<bool> deleteFileFromDisk(String fileId) async {
    final record = await _db.fileDao.getById(fileId);
    if (record == null) return false;
    final (_, fileItem) = record;

    if (fileItem.metadataId == null) return false;

    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(fileItem.metadataId!))).getSingleOrNull();

    if (metadata == null) return false;

    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath);
    final file = File(encryptedFilePath);

    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Удалить файл истории с диска по пути
  Future<bool> deleteHistoryFileFromDisk(String filePath) async {
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, filePath);
    final file = File(encryptedFilePath);

    if (await file.exists()) {
      await file.delete();
      logDebug('Deleted history file: $encryptedFilePath');
      return true;
    }
    logDebug('History file not found: $encryptedFilePath');
    return false;
  }

  /// Очистить физические файлы и метаданные, на которые больше нет ссылок
  Future<int> cleanupOrphanedFiles() async {
    int deletedCount = 0;
    try {
      // 1. Выбираем file_metadata, которые не используются
      final String sql = '''
        SELECT id, file_path 
        FROM file_metadata 
        WHERE id NOT IN (SELECT metadata_id FROM file_items WHERE metadata_id IS NOT NULL)
          AND id NOT IN (SELECT metadata_id FROM file_history WHERE metadata_id IS NOT NULL)
          AND id NOT IN (SELECT metadata_id FROM document_pages WHERE metadata_id IS NOT NULL)
      ''';

      final rows = await _db.customSelect(sql).get();

      final attachmentsPath = await _getAttachmentsPath();

      for (final row in rows) {
        final String id = row.read<String>('id');
        final String filePath = row.read<String>('file_path');

        // Удаляем физический файл
        final encryptedFilePath = p.join(attachmentsPath, filePath);
        final file = File(encryptedFilePath);

        if (await file.exists()) {
          await file.delete();
        }

        // Удаляем метаданные из БД
        await (_db.delete(
          _db.fileMetadata,
        )..where((m) => m.id.equals(id))).go();
        deletedCount++;
      }

      // 2. Ищем файлы на диске, которых нет в таблице file_metadata вообще (рассинхронизация)
      final dir = Directory(attachmentsPath);
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final fileName = p.basename(entity.path);
            final exists = await (_db.select(
              _db.fileMetadata,
            )..where((m) => m.filePath.equals(fileName))).getSingleOrNull();
            if (exists == null) {
              await entity.delete();
              deletedCount++;
            }
          }
        }
      }

      if (deletedCount > 0) {
        logInfo(
          'Cleaned up $deletedCount orphaned files',
          tag: 'FileStorageService',
        );
      }
    } catch (e, s) {
      logError(
        'Error cleaning up orphaned files: $e',
        stackTrace: s,
        tag: 'FileStorageService',
      );
    }
    return deletedCount;
  }
}
