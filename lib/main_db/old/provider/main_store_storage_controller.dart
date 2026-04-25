import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/old/main_store_manager.dart';
import 'package:hoplixi/main_db/old/models/db_errors.dart';
import 'package:hoplixi/main_db/old/models/db_state.dart';
import 'package:hoplixi/main_db/old/provider/db_history_provider.dart';
import 'package:hoplixi/main_db/old/provider/main_store_session_contract.dart';
import 'package:hoplixi/main_db/old/services/main_store_maintenance_service.dart';

final mainStoreStorageControllerProvider = Provider<MainStoreStorageController>(
  (ref) => const MainStoreStorageController(),
);

class MainStoreStorageController {
  const MainStoreStorageController();

  Future<void> runStartupCleanup({
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required String logTag,
  }) async {
    try {
      final store = manager.currentStore;
      if (store == null) {
        return;
      }

      final storePath = manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        return;
      }

      await maintenanceService.runStartupCleanup(
        store: store,
        storePath: storePath,
      );
    } catch (error, stackTrace) {
      logError(
        'Startup cleanup failed: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
    }
  }

  Future<bool> deleteStore({
    required Ref ref,
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required MainStoreSessionBridge session,
    required String path,
    required bool deleteFromDisk,
    required String logTag,
  }) async {
    try {
      logInfo('Deleting store at: $path', tag: logTag);

      session.setState(
        session.readState().copyWith(
          status: DatabaseStatus.loading,
          error: null,
        ),
      );

      if (manager.currentStorePath == path && manager.isStoreOpen) {
        await manager.closeStore();
      }

      final dbHistoryService = await ref.read(dbHistoryProvider.future);
      await dbHistoryService.deleteByPath(path);

      if (deleteFromDisk && await maintenanceService.storageDirectoryExists(path)) {
        await maintenanceService.deleteStorageDirectory(path);
      }

      session.setState(const DatabaseState(status: DatabaseStatus.idle));
      logInfo('Store deleted successfully', tag: logTag);
      return true;
    } catch (error, stackTrace) {
      logError(
        'Unexpected error deleting store: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );

      session.setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message: 'Неожиданная ошибка при удалении хранилища: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> deleteStoreFromDisk({
    required Ref ref,
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required MainStoreSessionBridge session,
    required String path,
    required String logTag,
  }) async {
    try {
      logInfo('Deleting store from disk at: $path', tag: logTag);

      session.setState(
        session.readState().copyWith(
          status: DatabaseStatus.loading,
          error: null,
        ),
      );

      if (manager.currentStorePath == path && manager.isStoreOpen) {
        await manager.closeStore();
      }

      if (!await maintenanceService.storageDirectoryExists(path)) {
        session.setErrorState(
          DatabaseState(
            status: DatabaseStatus.error,
            error: DatabaseError.recordNotFound(
              message: 'Директория хранилища не найдена',
              data: <String, dynamic>{'path': path},
              timestamp: DateTime.now(),
            ),
          ),
        );
        return false;
      }

      await maintenanceService.deleteStorageDirectory(path);

      final dbHistoryService = await ref.read(dbHistoryProvider.future);
      final historyDeleted = await dbHistoryService.deleteByPath(path);
      if (historyDeleted) {
        logInfo('Store history entry deleted successfully', tag: logTag);
      } else {
        logWarning('Failed to delete store history entry: $path', tag: logTag);
      }

      session.setState(const DatabaseState(status: DatabaseStatus.idle));
      logInfo('Store deleted from disk successfully', tag: logTag);
      return true;
    } catch (error, stackTrace) {
      logError(
        'Unexpected error deleting store from disk: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );

      session.setErrorState(
        DatabaseState(
          status: DatabaseStatus.error,
          error: DatabaseError.unknown(
            message:
                'Неожиданная ошибка при удалении хранилища с диска: $error',
            timestamp: DateTime.now(),
            stackTrace: stackTrace,
          ),
        ),
      );
      return false;
    }
  }

  Future<String?> getAttachmentsPath({
    required DatabaseState state,
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required String logTag,
  }) async {
    try {
      if (!state.isOpen) {
        logWarning(
          'Store is not open, cannot get attachments path',
          tag: logTag,
        );
        return null;
      }

      final storePath = manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        logError(
          'Failed to get attachments path: store path is null',
          tag: logTag,
        );
        return null;
      }

      return maintenanceService.getAttachmentsPath(storePath);
    } catch (error, stackTrace) {
      logError(
        'Unexpected error getting attachments path: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
      return null;
    }
  }

  Future<String?> getDecryptedAttachmentsPath({
    required DatabaseState state,
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required String logTag,
  }) async {
    try {
      if (!state.isOpen) {
        logWarning(
          'Store is not open, cannot get decrypted attachments path',
          tag: logTag,
        );
        return null;
      }

      final storePath = manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        logError(
          'Failed to get decrypted attachments path: store path is null',
          tag: logTag,
        );
        return null;
      }

      return maintenanceService.getDecryptedAttachmentsPath(storePath);
    } catch (error, stackTrace) {
      logError(
        'Unexpected error getting decrypted attachments path: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
      return null;
    }
  }

  Future<String?> createSubfolder({
    required DatabaseState state,
    required MainStoreManager manager,
    required MainStoreMaintenanceService maintenanceService,
    required String folderName,
    required String logTag,
  }) async {
    try {
      if (!state.isOpen) {
        logWarning('Store is not open, cannot create subfolder', tag: logTag);
        return null;
      }

      final storePath = manager.currentStorePath;
      if (storePath == null || storePath.isEmpty) {
        logError('Failed to create subfolder: store path is null', tag: logTag);
        return null;
      }

      final path = await maintenanceService.createSubfolder(
        storePath: storePath,
        folderName: folderName,
      );

      logInfo('Subfolder created: $path', tag: logTag);
      return path;
    } catch (error, stackTrace) {
      logError(
        'Unexpected error creating subfolder: $error',
        stackTrace: stackTrace,
        tag: logTag,
      );
      return null;
    }
  }

  Future<void> cleanupDecryptedAttachments({
    required MainStoreMaintenanceService maintenanceService,
    required String? dirPath,
  }) {
    return maintenanceService.cleanupDecryptedAttachmentsDir(dirPath);
  }
}
