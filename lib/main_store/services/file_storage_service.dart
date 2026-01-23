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
      tagsIds: tagsIds,
    );

    return _db.fileDao.createFile(dto);
  }

  /// Расшифровать файл в указанный путь
  Future<String> decryptFile({
    required String fileId,
    void Function(int, int)? onProgress,
  }) async {
    final fileData = await _db.fileDao.getFileById(fileId);
    if (fileData == null) {
      throw Exception('File not found in database');
    }

    // Получаем FileMetadata через metadataId
    if (fileData.metadataId == null) {
      throw Exception('File has no metadata');
    }

    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(fileData.metadataId!))).getSingleOrNull();

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
    final currentFile = await _db.fileDao.getFileById(fileId);
    if (currentFile == null) throw Exception('File not found');

    // Получаем FileMetadata
    if (currentFile.metadataId == null) {
      throw Exception('File has no metadata');
    }

    final currentMetadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(currentFile.metadataId!))).getSingleOrNull();

    if (currentMetadata == null) {
      throw Exception('File metadata not found');
    }

    // 1. Создаем запись в истории
    String? categoryName;
    if (currentFile.categoryId != null) {
      final cat = await _db.categoryDao.getCategoryById(
        currentFile.categoryId!,
      );
      categoryName = cat?.name;
    }

    final historyDto = CreateFileHistoryDto(
      originalFileId: currentFile.id,
      action: ActionInHistory.modified.value,
      metadataId: currentFile.metadataId!,
      name: currentFile.name,
      description: currentFile.description,
      categoryName: categoryName,
      usedCount: currentFile.usedCount,
      isFavorite: currentFile.isFavorite,
      isArchived: currentFile.isArchived,
      isPinned: currentFile.isPinned,
      isDeleted: currentFile.isDeleted,
      originalCreatedAt: currentFile.createdAt,
      originalModifiedAt: currentFile.modifiedAt,
      originalLastAccessedAt: currentFile.lastUsedAt,
    );
    await _db.fileHistoryDao.createFileHistory(historyDto);

    // 2. Шифруем новый файл
    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
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

    // 4. Создаем новую запись FileMetadata
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

    // 5. Обновляем запись в таблице Files
    final updateQuery = _db.update(_db.files)
      ..where((f) => f.id.equals(fileId));
    await updateQuery.write(
      FilesCompanion(
        metadataId: Value(newMetadataId),
        modifiedAt: Value(DateTime.now()),
      ),
    );
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
    final fileData = await _db.fileDao.getFileById(fileId);
    if (fileData == null) return false;

    if (fileData.metadataId == null) return false;

    final metadata = await (_db.select(
      _db.fileMetadata,
    )..where((m) => m.id.equals(fileData.metadataId!))).getSingleOrNull();

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
}
