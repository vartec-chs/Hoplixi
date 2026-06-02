import 'dart:async';

import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/vault_db/core/api/vault_core_api.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/services/db_history_services/db_history_services.dart';
import 'package:hoplixi/vault_db/services/lifecycle/ivault_lifecycle_service.dart';
import 'package:hoplixi/vault_db/services/lifecycle/vault_lifecycle_service.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/session/ivault_session_holder.dart';
import 'package:hoplixi/vault_db/services/session/vault_session_holder.dart';
import 'package:hoplixi/vault_db/services/storage/ivault_storage_manager.dart';
import 'package:hoplixi/vault_db/services/storage/vault_storage_manager.dart';
import 'package:hoplixi/vault_db/usecases/close_main_store.dart';
import 'package:hoplixi/vault_db/usecases/create_main_store.dart';
import 'package:hoplixi/vault_db/usecases/open_main_store.dart';
import 'package:hoplixi/vault_db/usecases/update_main_store.dart';
import 'package:result_dart/result_dart.dart';

/// Тайпалиас для сохранения полной обратной совместимости во всем проекте.
typedef VaultDBManager = VaultDBFacade;

class VaultDBManagerFactory {
  VaultDBManagerFactory({required this.dbHistoryService})
    : createVaultDB = CreateVaultDB(),
       openVaultDB = OpenVaultDB(),
       closeVaultDB = CloseVaultDB(),
       updateVaultDB = UpdateVaultDB(),
       storageService = const VaultDBFileService();

  final DatabaseHistoryService dbHistoryService;
  final CreateVaultDB createVaultDB;
  final OpenVaultDB openVaultDB;
  final CloseVaultDB closeVaultDB;
  final UpdateVaultDB updateVaultDB;
  final VaultDBFileService storageService;

  VaultDBManager create() {
    final sessionHolder = VaultSessionHolder();
    final storageManager = VaultStorageManager(
      sessionHolder: sessionHolder,
      storageService: storageService,
    );
    final lifecycleService = VaultLifecycleService(
      sessionHolder: sessionHolder,
      storageManager: storageManager,
      dbHistoryService: dbHistoryService,
      createVaultDB: createVaultDB,
      openVaultDB: openVaultDB,
      closeVaultDB: closeVaultDB,
      updateVaultDB: updateVaultDB,
    );

    return VaultDBFacade(
      sessionHolder: sessionHolder,
      lifecycleService: lifecycleService,
      storageManager: storageManager,
    );
  }
}

/// Тонкий фасад над сервисами управления хранилищем VaultDB.
///
/// Агрегирует независимые слои (сессию, файлы, жизненный цикл) и предоставляет
/// единый плоский API для GUI и CLI.
class VaultDBFacade {
  final IVaultSessionHolder _sessionHolder;
  final IVaultLifecycleService _lifecycleService;
  final IVaultStorageManager _storageManager;

  VaultDBFacade({
    required IVaultSessionHolder sessionHolder,
    required IVaultLifecycleService lifecycleService,
    required IVaultStorageManager storageManager,
  }) : _sessionHolder = sessionHolder,
       _lifecycleService = lifecycleService,
       _storageManager = storageManager;

  // --- Управление состоянием сессии ---

  bool get isStoreOpen => _sessionHolder.isStoreOpen;

  VaultCoreApi? get currentApi => _sessionHolder.currentApi;

  VaultDB? get currentDB => currentApi?.db;

  Session? get currentSession => _sessionHolder.currentSession;

  String? get currentStorePath => _sessionHolder.currentStorePath;

  Stream<Session?> get sessionStream => _sessionHolder.sessionStream;

  // --- Файловые операции ---

  String? getAttachmentsPath() => _storageManager.getAttachmentsPath();

  String? getDecryptedAttachmentsPath() =>
      _storageManager.getDecryptedAttachmentsPath();

  AsyncResultDart<String, AppError> createSubfolder(String folderName) =>
      _storageManager.createSubfolder(folderName);

  // --- Жизненный цикл хранилища ---

  AsyncResultDart<Session, AppError> createStore(
    CreateStoreDto dto,
    String masterPassword,
  ) {
    return _lifecycleService.createStore(
      dto: dto,
      masterPassword: masterPassword,
    );
  }

  AsyncResultDart<Session, AppError> openStore(
    OpenStoreDto dto,
    String masterPassword, {
    bool allowMigration = false,
  }) {
    return _lifecycleService.openStore(
      dto: dto,
      masterPassword: masterPassword,
      allowMigration: allowMigration,
    );
  }

  AsyncResultDart<Unit, AppError> closeStore() =>
      _lifecycleService.closeStore();

  AsyncResultDart<Unit, AppError> deleteStore(
    String path, {
    bool deleteFromDisk = true,
  }) {
    return _lifecycleService.deleteStore(path, deleteFromDisk: deleteFromDisk);
  }

  AsyncResultDart<Unit, AppError> deleteStoreFromDisk(String path) {
    return _lifecycleService.deleteStore(path, deleteFromDisk: true);
  }

  AsyncResultDart<StoreInfoDto, AppError> updateStore(PatchStoreDto dto) =>
      _lifecycleService.updateStore(dto);

  AsyncResultDart<StoreInfoDto, AppError> getStoreInfo() =>
      _lifecycleService.getStoreInfo();
}
