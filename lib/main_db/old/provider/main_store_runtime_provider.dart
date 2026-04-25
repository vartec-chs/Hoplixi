import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/old/main_store_manager.dart';
import 'package:hoplixi/main_db/old/provider/db_history_provider.dart';
import 'package:hoplixi/main_db/old/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_db/old/services/main_store_backup_service.dart';
import 'package:hoplixi/main_db/old/services/main_store_maintenance_service.dart';
import 'package:hoplixi/setup/di_init.dart';

final mainStoreManagerRuntimeProvider = FutureProvider<MainStoreManager>((
  ref,
) async {
  final dbHistoryService = await ref.read(dbHistoryProvider.future);
  final keyService = DbKeyDerivationService(getIt<FlutterSecureStorage>());
  return MainStoreManager(dbHistoryService, keyService);
});

final mainStoreBackupServiceProvider = Provider<MainStoreBackupService>((ref) {
  return MainStoreBackupService();
});

final mainStoreMaintenanceServiceProvider =
    Provider<MainStoreMaintenanceService>((ref) {
      ref.onDispose(() {
        logInfo(
          'Освобождение ресурсов mainStoreMaintenanceServiceProvider',
          tag: 'MainStoreMaintenanceServiceProvider',
        );
      });

      return MainStoreMaintenanceService();
    });
