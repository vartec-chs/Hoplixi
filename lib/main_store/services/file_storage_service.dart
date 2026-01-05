import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_crypto/file_crypto.dart';
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
    final encryptedFileName = '$filePathUuid.enc';
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

    final key = await _getAttachmentKey();
    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, '${fileData.filePath}');

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
      name: currentFile.name,
      fileName: currentFile.fileName,
      fileExtension: currentFile.fileExtension,
      filePath: currentFile.filePath!,
      mimeType: currentFile.mimeType,
      fileSize: currentFile.fileSize,
      fileHash: currentFile.fileHash ?? '',
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
    final newEncryptedFileName = '$newFilePathUuid.enc';
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

    // 4. Обновляем запись в таблице Files
    final updateQuery = _db.update(_db.files)
      ..where((f) => f.id.equals(fileId));
    await updateQuery.write(
      FilesCompanion(
        filePath: Value(newEncryptedFileName),
        fileSize: Value(newFileSize),
        fileHash: Value(newFileHash),
        fileName: Value(newFileName),
        fileExtension: Value(newFileExtension),
        mimeType: Value(newMimeType),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Удалить файл с диска (используется при удалении из БД)
  Future<void> deleteFileFromDisk(String fileId) async {
    final fileData = await _db.fileDao.getFileById(fileId);
    if (fileData == null) return;

    final attachmentsPath = await _getAttachmentsPath();
    final encryptedFilePath = p.join(attachmentsPath, fileData.filePath);
    final file = File(encryptedFilePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
