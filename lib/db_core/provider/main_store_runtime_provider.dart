import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/main_store_manager.dart';
import 'package:hoplixi/db_core/provider/db_history_provider.dart';
import 'package:hoplixi/db_core/services/db_key_derivation_service.dart';
import 'package:hoplixi/db_core/services/main_store_backup_service.dart';
import 'package:hoplixi/db_core/services/main_store_maintenance_service.dart';
import 'package:hoplixi/setup/di_init.dart';

class MainStoreRuntime {
  const MainStoreRuntime({
    required this.backupService,
    required this.maintenanceService,
  });

  final MainStoreBackupService backupService;
  final MainStoreMaintenanceService maintenanceService;
}

final mainStoreManagerRuntimeProvider = FutureProvider<MainStoreManager>((
  ref,
) async {
  final dbHistoryService = await ref.read(dbHistoryProvider.future);
  final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
  return MainStoreManager(dbHistoryService, keyService);
});

final mainStoreRuntimeProvider = FutureProvider<MainStoreRuntime>((ref) async {
  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов mainStoreRuntimeProvider',
      tag: 'MainStoreRuntimeProvider',
    );
  });

  return MainStoreRuntime(
    backupService: MainStoreBackupService(),
    maintenanceService: MainStoreMaintenanceService(),
  );
});
