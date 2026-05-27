import 'package:hoplixi/core/errors/errors.dart';
import 'package:result_dart/result_dart.dart';

abstract interface class IVaultStorageManager {
  /// Возвращает путь к зашифрованным вложениям
  String? getAttachmentsPath();

  /// Возвращает путь к расшифрованным (кэшированным) вложениям
  String? getDecryptedAttachmentsPath();

  /// Создает подпапку внутри директории активного хранилища
  AsyncResultDart<String, AppError> createSubfolder(String folderName);

  /// Проверяет существование директории хранилища по пути
  Future<bool> storageDirectoryExists(String storePath);

  /// Полностью удаляет директорию хранилища с диска
  Future<void> deleteStorageDirectory(String storePath);

  /// Разрешает существующий путь к хранилищу (нормализация)
  Future<String> resolveExistingStoragePath(String path);
}
