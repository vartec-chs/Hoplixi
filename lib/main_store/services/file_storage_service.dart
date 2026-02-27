import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/store_settings_keys.dart';
import 'package:hoplixi/rust/api/crypt_api.dart' as crypt;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileStorageService {
  final MainStore _db;
  final String _attachmentsPath;
  final String _decryptedAttachmentsPath;

  FileStorageService(
    this._db,
    this._attachmentsPath,
    this._decryptedAttachmentsPath,
  );

  /// Получить ключ шифрования из метаданных хранилища.
  Future<String> _getAttachmentKey() async {
    final meta = await _db.select(_db.storeMetaTable).getSingle();
    return meta.attachmentKey;
  }

  /// Получить путь к директории вложений, создав её при необходимости.
  Future<String> _getAttachmentsPath() async {
    final directory = Directory(_attachmentsPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return _attachmentsPath;
  }

  /// Зашифровать файл через crypt_api и вернуть базовое имя выходного файла.
  ///
  /// [uuid] — используется как имя выходного файла.
  /// [onProgress] — коллбэк прогресса (0.0–100.0).
  Future<String> _encryptFile({
    required String inputPath,
    required String outputDir,
    required String password,
    required String uuid,
    void Function(double percentage)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final opts = crypt.FrbEncryptOptions(
      inputPath: inputPath,
      outputDir: outputDir,
      password: password,
      gzipCompressed: false,
      uuid: uuid,
      outputExtension: MainConstants.encryptedFileExtension,
      tempDir: tempDir.path,
      metadata: const [],
      chunkSize: const crypt.FrbChunkSizePreset.desktop(),
    );

    String? resultPath;

    await for (final event in crypt.encryptFile(opts: opts)) {
      switch (event) {
        case crypt.FrbEncryptEvent_Progress(:final field0):
          onProgress?.call(field0.percentage);
        case crypt.FrbEncryptEvent_Done(:final field0):
          resultPath = field0.outputPath;
        case crypt.FrbEncryptEvent_Error(:final field0):
          throw Exception('Ошибка шифрования: $field0');
      }
    }

    if (resultPath == null) {
      throw Exception('Шифрование завершилось без результата');
    }

    return p.basename(resultPath);
  }

  /// Расшифровать файл через crypt_api в директорию [outputDir].
  ///
  /// Возвращает путь к расшифрованному файлу.
  Future<String> _decryptFile({
    required String encryptedFilePath,
    required String outputDir,
    required String password,
    void Function(double percentage)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final opts = crypt.FrbDecryptOptions(
      inputPath: encryptedFilePath,
      outputDir: outputDir,
      password: password,
      tempDir: tempDir.path,
      chunkSize: const crypt.FrbChunkSizePreset.desktop(),
    );

    String? resultPath;

    await for (final event in crypt.decryptFile(opts: opts)) {
      switch (event) {
        case crypt.FrbDecryptEvent_Progress(:final field0):
          onProgress?.call(field0.percentage);
        case crypt.FrbDecryptEvent_Done(:final field0):
          resultPath = field0.outputPath;
        case crypt.FrbDecryptEvent_Error(:final field0):
          throw Exception('Ошибка расшифровки: $field0');
      }
    }

    if (resultPath == null) {
      throw Exception('Расшифровка завершилась без результата');
    }

    return resultPath;
  }

  /// Импортировать файл: шифрует и сохраняет в БД.
  Future<String> importFile({
    required File sourceFile,
    required String name,
    String? description,
    String? categoryId,
    String? noteId,
    required List<String> tagsIds,
    void Function(double percentage)? onProgress,
  }) async {
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final filePathUuid = const Uuid().v4();
    final extension = p.extension(sourceFile.path);

    final encryptedFileName = await _encryptFile(
      inputPath: sourceFile.path,
      outputDir: attachmentsPath,
      password: key,
      uuid: filePathUuid,
      onProgress: onProgress,
    );

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

  /// Расшифровать файл в директорию для расшифрованных вложений.
  Future<String> decryptFile({
    required String fileId,
    void Function(double percentage)? onProgress,
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

    // Расшифровываем во временную директорию, потому что crypt_api
    // восстанавливает оригинальное имя файла из заголовка.
    final tempDir = await Directory.systemTemp.createTemp('hoplixi_decrypt_');
    try {
      final decryptedPath = await _decryptFile(
        encryptedFilePath: encryptedFilePath,
        outputDir: tempDir.path,
        password: key,
        onProgress: onProgress,
      );

      final decryptedFile = File(decryptedPath);
      if (!await decryptedFile.exists()) {
        throw Exception(
          'Decryption finished but file not found at $decryptedPath',
        );
      }

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
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Обновить содержимое файла: старый файл — в историю, новый шифруется.
  Future<void> updateFileContent({
    required String fileId,
    required File newFile,
    void Function(double percentage)? onProgress,
  }) async {
    final record = await _db.fileDao.getById(fileId);
    if (record == null) throw Exception('File not found');
    final (_, currentFileItem) = record;

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

    // Историю пишет SQL-триггер file_content_update_history автоматически
    // при обновлении metadata_id в file_items (когда история включена).
    final historyEnabledStr =
        await (_db.select(_db.storeSettings)
              ..where((s) => s.key.equals(StoreSettingsKeys.historyEnabled)))
            .getSingleOrNull();
    final isHistoryEnabled =
        historyEnabledStr == null || historyEnabledStr.value == 'true';

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final newFilePathUuid = const Uuid().v4();

    final newEncryptedFileName = await _encryptFile(
      inputPath: newFile.path,
      outputDir: attachmentsPath,
      password: key,
      uuid: newFilePathUuid,
      onProgress: onProgress,
    );

    final digest = await sha256.bind(newFile.openRead()).first;
    final newFileHash = digest.toString();
    final newFileSize = await newFile.length();
    final newFileName = p.basename(newFile.path);
    final newFileExtension = p.extension(newFile.path);
    final newMimeType =
        lookupMimeType(newFile.path) ?? 'application/octet-stream';

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

    // Триггер file_content_update_history сработает и запишет историю.
    await (_db.update(_db.fileItems)..where((f) => f.itemId.equals(fileId)))
        .write(FileItemsCompanion(metadataId: Value(newMetadataId)));

    if (!isHistoryEnabled) {
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

  /// Импортировать файл страницы (только метаданные).
  Future<String> importPageFile({
    required File sourceFile,
    void Function(double percentage)? onProgress,
  }) async {
    if (!await sourceFile.exists()) {
      throw Exception('Source file not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final filePathUuid = const Uuid().v4();
    final extension = p.extension(sourceFile.path);

    final encryptedFileName = await _encryptFile(
      inputPath: sourceFile.path,
      outputDir: attachmentsPath,
      password: key,
      uuid: filePathUuid,
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

  /// Расшифровать файл страницы по metadataId.
  Future<String> decryptPageFile({
    required String metadataId,
    void Function(double percentage)? onProgress,
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
      final decryptedPath = await _decryptFile(
        encryptedFilePath: encryptedFilePath,
        outputDir: tempDir.path,
        password: key,
        onProgress: onProgress,
      );

      final decryptedFile = File(decryptedPath);
      if (!await decryptedFile.exists()) {
        throw Exception(
          'Decryption finished but file not found at $decryptedPath',
        );
      }

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
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Обновить содержимое файла страницы (обновляет метаданные).
  Future<void> updatePageFile({
    required String metadataId,
    required File newFile,
    void Function(double percentage)? onProgress,
  }) async {
    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(metadataId))).getSingleOrNull();

    if (metadata == null) throw Exception('File metadata not found');

    final attachmentsPath = await _getAttachmentsPath();
    final oldEncryptedFilePath = p.join(attachmentsPath, metadata.filePath);
    final oldFile = File(oldEncryptedFilePath);
    if (await oldFile.exists()) {
      await oldFile.delete();
    }

    final key = await _getAttachmentKey();
    final newFilePathUuid = const Uuid().v4();

    final newEncryptedFileName = await _encryptFile(
      inputPath: newFile.path,
      outputDir: attachmentsPath,
      password: key,
      uuid: newFilePathUuid,
      onProgress: onProgress,
    );

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

  /// Удалить файл страницы с диска по metadataId и удалить запись из БД.
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

  /// Удалить файл с диска (используется при удалении записи из БД).
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

  /// Удалить файл истории с диска по пути.
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

  /// Очистить физические файлы и метаданные, на которые больше нет ссылок.
  Future<int> cleanupOrphanedFiles() async {
    int deletedCount = 0;
    try {
      const String sql = '''
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

        final encryptedFilePath = p.join(attachmentsPath, filePath);
        final file = File(encryptedFilePath);

        if (await file.exists()) {
          await file.delete();
        }

        await (_db.delete(
          _db.fileMetadata,
        )..where((m) => m.id.equals(id))).go();
        deletedCount++;
      }

      // Ищем файлы на диске, которых нет в таблице file_metadata (рассинхронизация).
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
