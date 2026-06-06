import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/session/ivault_session_holder.dart';
import 'package:result_dart/result_dart.dart';
import 'ivault_storage_manager.dart';

class VaultStorageManager implements IVaultStorageManager {
  final IVaultSessionHolder _sessionHolder;
  final VaultDBFileService _storageService;

  VaultStorageManager({
    required this._sessionHolder,
    required this._storageService,
  });

  @override
  String? getAttachmentsPath() {
    final storePath = _sessionHolder.currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      return null;
    }
    return _storageService.getAttachmentsPath(storePath);
  }

  @override
  String? getDecryptedAttachmentsPath() {
    final storePath = _sessionHolder.currentStorePath;
    if (storePath == null || storePath.isEmpty) {
      return null;
    }
    return _storageService.getDecryptedAttachmentsPath(storePath);
  }

  @override
  AsyncResultDart<String, AppError> createSubfolder(String folderName) async {
    try {
      final storePath = _sessionHolder.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.notInitialized,
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final path = await _storageService.createSubfolder(
        storePath: storePath,
        folderName: folderName,
      );
      return Success(path);
    } catch (error, stackTrace) {
      if (error is AppError) {
        return Failure(error);
      }
      return Failure(
        AppError.fileSystem(
          code: FileSystemErrorCode.unknown,
          message: 'Не удалось создать подпапку хранилища',
          cause: error,
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<bool> storageDirectoryExists(String storePath) {
    return _storageService.storageDirectoryExists(storePath);
  }

  @override
  Future<void> deleteStorageDirectory(String storePath) {
    return _storageService.deleteStorageDirectory(storePath);
  }

  @override
  Future<String> resolveExistingStoragePath(String path) {
    return _storageService.resolveExistingStoragePath(path);
  }
}
