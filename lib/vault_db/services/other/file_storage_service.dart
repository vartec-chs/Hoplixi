import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/rust/api/crypt_api.dart' as crypt;
import 'package:hoplixi/rust/api/crypt_api/types.dart' as crypt_types;
import 'package:hoplixi/vault_db/core/config/store_settings_keys.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/repositories.dart';
import 'package:hoplixi/vault_db/core/services/entities/file_service.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileStorageService {
  final VaultDB _db;
  final String _attachmentsPath;
  final String _decryptedAttachmentsPath;

  final FileService _fileService;
  final FileRepository _fileRepository;
  final FileMetadataRepository _fileMetadataRepository;

  FileStorageService({
    required VaultDB db,
    required String attachmentsPath,
    required String decryptedAttachmentsPath,
    required FileService fileService,
    required FileRepository fileRepository,
    required FileMetadataRepository fileMetadataRepository,
  }) : _db = db,
       _attachmentsPath = attachmentsPath,
       _decryptedAttachmentsPath = decryptedAttachmentsPath,
       _fileService = fileService,
       _fileRepository = fileRepository,
       _fileMetadataRepository = fileMetadataRepository;

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
    final opts = crypt_types.FrbEncryptOptions(
      inputPath: inputPath,
      outputDir: outputDir,
      password: password,
      gzipCompressed: false,
      uuid: uuid,
      outputExtension: MainConstants.encryptedFileExtension,
      tempDir: tempDir.path,
      metadata: const [],
      chunkSize: const crypt_types.FrbChunkSizePreset.desktop(),
    );

    String? resultPath;

    await for (final event in crypt.encryptFile(opts: opts)) {
      switch (event) {
        case crypt_types.FrbEncryptEvent_Progress(:final field0):
          onProgress?.call(field0.percentage);
        case crypt_types.FrbEncryptEvent_Done(:final field0):
          resultPath = field0.outputPath;
        case crypt_types.FrbEncryptEvent_Error(:final field0):
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
    final opts = crypt_types.FrbDecryptOptions(
      inputPath: encryptedFilePath,
      outputDir: outputDir,
      password: password,
      tempDir: tempDir.path,
      chunkSize: const crypt_types.FrbChunkSizePreset.desktop(),
    );

    String? resultPath;

    await for (final event in crypt.decryptFile(opts: opts)) {
      switch (event) {
        case crypt_types.FrbDecryptEvent_Progress(:final field0):
          onProgress?.call(field0.percentage);
        case crypt_types.FrbDecryptEvent_Done(:final field0):
          resultPath = field0.outputPath;
        case crypt_types.FrbDecryptEvent_Error(:final field0):
          throw Exception('Ошибка расшифровки: $field0');
      }
    }

    if (resultPath == null) {
      throw Exception('Расшифровка завершилось без результата');
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
      item: VaultItemCreateDto(
        name: name,
        description: description,
        categoryId: categoryId,
      ),
      file: const FileDataDto(),
      metadata: FileMetadataDataDto(
        fileName: fileName,
        fileExtension: extension,
        filePath: encryptedFileName,
        mimeType: mimeType,
        fileSize: fileSize,
        sha256: fileHash,
      ),
      tagIds: tagsIds,
    );

    final result = await _fileService.create(dto);
    return result.getOrThrow();
  }

  /// Расшифровать файл в директорию для расшифрованных вложений.
  Future<String> decryptFile({
    required String fileId,
    void Function(double percentage)? onProgress,
  }) async {
    final viewResult = await _fileRepository.getViewById(fileId);
    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) {
      throw Exception('File not found in database');
    }
    final metadata = view.metadata;

    if (metadata == null) {
      throw Exception('File metadata not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath ?? '');

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
    final viewResult = await _fileRepository.getViewById(fileId);
    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) {
      throw Exception('File not found');
    }
    final currentMetadata = view.metadata;

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

    // Вставляем новую запись в file_metadata через репозиторий
    final metadataDto = FileMetadataDataDto(
      fileName: newFileName,
      fileExtension: newFileExtension,
      filePath: newEncryptedFileName,
      mimeType: newMimeType,
      fileSize: newFileSize,
      sha256: newFileHash,
    );

    final newMetadataId = (await _fileMetadataRepository.createMetadata(
      metadataDto,
    )).getOrThrow();

    // Обновляем file item с новым metadataId через _fileService.update
    final patchDto = PatchFileDto(
      item: VaultItemPatchDto(
        itemId: fileId,
        name: FieldUpdate.set(view.item.name),
      ),
      file: PatchFileDataDto(metadataId: FieldUpdate.set(newMetadataId)),
    );

    final updateRes = await _fileService.update(patchDto);
    updateRes.getOrThrow();

    if (!isHistoryEnabled) {
      final oldEncryptedFilePath = p.join(
        attachmentsPath,
        currentMetadata.filePath ?? '',
      );
      final oldFile = File(oldEncryptedFilePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      await (_db.delete(
        _db.fileMetadata,
      )..where((m) => m.id.equals(currentMetadata.id))).go();
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

    final metadataDto = FileMetadataDataDto(
      fileName: fileName,
      fileExtension: extension,
      filePath: encryptedFileName,
      mimeType: mimeType,
      fileSize: fileSize,
      sha256: fileHash,
    );

    final metadataId = (await _fileMetadataRepository.createMetadata(
      metadataDto,
    )).getOrThrow();
    return metadataId;
  }

  /// Расшифровать файл страницы по metadataId.
  Future<String> decryptPageFile({
    required String metadataId,
    void Function(double percentage)? onProgress,
  }) async {
    final metadataResult = await _fileMetadataRepository.getMetadataById(
      metadataId,
    );
    final metadata = metadataResult.getOrThrow().getOrNull();
    if (metadata == null) {
      throw Exception('File metadata not found');
    }

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath ?? '');

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
    final metadataResult = await _fileMetadataRepository.getMetadataById(
      metadataId,
    );
    final metadata = metadataResult.getOrThrow().getOrNull();
    if (metadata == null) {
      throw Exception('File metadata not found');
    }

    final attachmentsPath = await _getAttachmentsPath();
    final oldEncryptedFilePath = p.join(
      attachmentsPath,
      metadata.filePath ?? '',
    );
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

    final patchDto = PatchFileMetadataDto(
      id: metadataId,
      fileName: FieldUpdate.set(newFileName),
      fileExtension: FieldUpdate.set(newFileExtension),
      filePath: FieldUpdate.set(newEncryptedFileName),
      mimeType: FieldUpdate.set(newMimeType),
      fileSize: FieldUpdate.set(newFileSize),
      sha256: FieldUpdate.set(newFileHash),
    );

    final updateRes = await _fileMetadataRepository.updateMetadata(patchDto);
    updateRes.getOrThrow();
  }

  /// Удалить файл страницы с диска по metadataId и удалить запись из БД.
  Future<bool> deletePageFile(String metadataId) async {
    final metadataResult = await _fileMetadataRepository.getMetadataById(
      metadataId,
    );
    final metadata = metadataResult.getOrThrow().getOrNull();
    if (metadata == null) return false;

    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath ?? '');
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
    final viewResult = await _fileRepository.getViewById(fileId);
    final view = viewResult.getOrThrow().getOrNull();
    if (view == null) return false;
    final metadata = view.metadata;

    if (metadata == null) return false;

    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, metadata.filePath ?? '');
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
      // 1. Ищем осиротевшие метаданные, на которые нет ссылок из file_items
      const String sql = '''
        SELECT id, file_path 
        FROM file_metadata 
        WHERE id NOT IN (SELECT metadata_id FROM file_items WHERE metadata_id IS NOT NULL)
      ''';

      final rows = await _db.customSelect(sql).get();
      final attachmentsPath = await _getAttachmentsPath();

      for (final row in rows) {
        final String id = row.read<String>('id');
        final String? filePath = row.readNullable<String>('file_path');

        if (filePath != null) {
          // Проверяем, не используется ли этот же физический файл в истории (в file_metadata_history)
          final historyRows = await _db
              .customSelect(
                'SELECT 1 FROM file_metadata_history WHERE file_path = ? LIMIT 1',
                variables: [Variable<String>(filePath)],
              )
              .get();

          if (historyRows.isEmpty) {
            final encryptedFilePath = p.join(attachmentsPath, filePath);
            final file = File(encryptedFilePath);
            if (await file.exists()) {
              await file.delete();
            }
          }
        }

        await (_db.delete(
          _db.fileMetadata,
        )..where((m) => m.id.equals(id))).go();
        deletedCount++;
      }

      // 2. Ищем файлы на диске, которых нет ни в таблице file_metadata, ни в file_metadata_history (рассинхронизация).
      final dir = Directory(attachmentsPath);
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final fileName = p.basename(entity.path);

            // Проверяем, есть ли файл в live-метаданных
            final liveExists = await (_db.select(
              _db.fileMetadata,
            )..where((m) => m.filePath.equals(fileName))).getSingleOrNull();

            if (liveExists == null) {
              // Проверяем, есть ли файл в исторических метаданных
              final historyExistsRows = await _db
                  .customSelect(
                    'SELECT 1 FROM file_metadata_history WHERE file_path = ? LIMIT 1',
                    variables: [Variable<String>(fileName)],
                  )
                  .get();

              if (historyExistsRows.isEmpty) {
                await entity.delete();
                deletedCount++;
              }
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
