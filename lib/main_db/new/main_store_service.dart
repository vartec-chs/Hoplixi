import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart' hide Session;
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/main_db/new/usecases/create_main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';

class MainStoreService {
  static const String _logTag = 'MainStoreService';

  final Lock _lock = Lock();
  final DatabaseHistoryService _dbHistoryService;
  final CreateMainStore _createMainStore;

  MainStoreService({
    required DatabaseHistoryService dbHistoryService,
    CreateMainStore? createMainStore,
  }) : _dbHistoryService = dbHistoryService,
       _createMainStore = createMainStore ?? CreateMainStore();

  AsyncResultDart<Session, AppError> createStore(
    CreateStoreDto dto,
    String masterPassword,
  ) async {
    return _lock.synchronized(() async {
      final result = await _createMainStore(
        dto: dto,
        masterPassword: masterPassword,
      );
      if (result.isError()) {
        return Failure(result.exceptionOrNull()!);
      }

      final session = result.getOrThrow();
      try {
        await _dbHistoryService.create(
          path: session.storeDirectoryPath,
          dbId: session.info.id,
          name: session.info.name,
          description: session.info.description,
          password: dto.saveMasterPassword ? masterPassword : null,
          savePassword: dto.saveMasterPassword,
        );
        logInfo('Created history entry for new store', tag: _logTag);
        return Success(session);
      } catch (error, stackTrace) {
        logWarning(
          'Failed to create history entry for new store',
          tag: _logTag,
          data: {
            'storeId': session.info.id,
            'storePath': session.storeDirectoryPath,
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
        return Success(session);
      }
    });
  }

  AsyncResultDart<StoreInfoDto, AppError> openStore(
    OpenStoreDto dto,
    String masterPassword,
  ) async {
    throw UnimplementedError(
      'MainStoreManagerV2.openStore is not implemented yet',
    );
  }

  AsyncResultDart<StoreInfoDto, AppError> updateStore(
    String storeId,
    UpdateStoreDto dto,
  ) async {
    throw UnimplementedError(
      'MainStoreManagerV2.updateStore is not implemented yet',
    );
  }

  String getAttachmentsPath(String storePath) {
    return _createMainStore.getAttachmentsPath(storePath);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return _createMainStore.getDecryptedAttachmentsPath(storePath);
  }

  Future<bool> storageDirectoryExists(String path) {
    return _createMainStore.storageDirectoryExists(path);
  }

  Future<void> deleteStorageDirectory(String path) {
    return _createMainStore.deleteStorageDirectory(path);
  }
}
