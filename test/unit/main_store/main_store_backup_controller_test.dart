// import 'dart:async';

// import 'package:flutter_test/flutter_test.dart';
// import 'package:hoplixi/db_core/main_store_manager.dart';
// import 'package:hoplixi/db_core/models/db_state.dart';
// import 'package:hoplixi/db_core/provider/main_store_backup_controller.dart';
// import 'package:hoplixi/db_core/provider/main_store_backup_models.dart';
// import 'package:hoplixi/db_core/provider/main_store_runtime_provider.dart';
// import 'package:hoplixi/db_core/provider/main_store_storage_controller.dart';
// import 'package:hoplixi/db_core/services/db_history_services.dart';
// import 'package:hoplixi/db_core/services/db_key_derivation_service.dart';
// import 'package:hoplixi/db_core/services/main_store_backup_service.dart';
// import 'package:hoplixi/db_core/services/main_store_maintenance_service.dart';

// void main() {
//   group('MainStoreBackupController', () {
//     test('returns null when store is not open', () async {
//       final storageController = _FakeStorageController();
//       final backupService = _FakeBackupService();
//       final manager = _FakeMainStoreManager()..path = '/tmp/store';
//       final controller = MainStoreBackupController(
//         storageController: storageController,
//       );

//       final result = await controller.createBackup(
//         state: const DatabaseState(status: DatabaseStatus.idle),
//         runtime: MainStoreRuntime(
//           manager: manager,
//           backupService: backupService,
//           maintenanceService: MainStoreMaintenanceService(),
//         ),
//         scope: BackupScope.full,
//         periodic: false,
//         maxBackupsPerStore: 10,
//         logTag: 'test',
//       );

//       expect(result, isNull);
//       expect(backupService.callCount, 0);
//     });

//     test('creates backup using storage controller attachments path', () async {
//       final storageController = _FakeStorageController(
//         attachmentsPath: '/tmp/store/attachments',
//       );
//       final backupService = _FakeBackupService();
//       final manager = _FakeMainStoreManager()..path = '/tmp/store';
//       final controller = MainStoreBackupController(
//         storageController: storageController,
//       );

//       final result = await controller.createBackup(
//         state: const DatabaseState(
//           status: DatabaseStatus.open,
//           path: '/tmp/store',
//           name: 'Demo',
//         ),
//         runtime: MainStoreRuntime(
//           manager: manager,
//           backupService: backupService,
//           maintenanceService: MainStoreMaintenanceService(),
//         ),
//         scope: BackupScope.full,
//         periodic: false,
//         maxBackupsPerStore: 7,
//         logTag: 'test',
//       );

//       expect(result, isNotNull);
//       expect(result?.backupPath, '/tmp/backups/demo');
//       expect(result?.scope, BackupScope.full);
//       expect(backupService.callCount, 1);
//       expect(backupService.lastAttachmentsPath, '/tmp/store/attachments');
//       expect(backupService.lastIncludeDatabase, isTrue);
//       expect(backupService.lastIncludeEncryptedFiles, isTrue);
//       expect(backupService.lastMaxBackupsPerStore, 7);
//     });

//     test('starts and stops periodic backup scheduling', () async {
//       final storageController = _FakeStorageController(
//         attachmentsPath: '/tmp/store/attachments',
//       );
//       final backupService = _FakeBackupService();
//       final manager = _FakeMainStoreManager()..path = '/tmp/store';
//       final controller = MainStoreBackupController(
//         storageController: storageController,
//       );
//       final runtime = MainStoreRuntime(
//         manager: manager,
//         backupService: backupService,
//         maintenanceService: MainStoreMaintenanceService(),
//       );

//       controller.startPeriodicBackup(
//         interval: const Duration(seconds: 1),
//         scope: BackupScope.full,
//         runImmediately: true,
//         maxBackupsPerStore: 10,
//         readState: () => const DatabaseState(
//           status: DatabaseStatus.open,
//           path: '/tmp/store',
//           name: 'Demo',
//         ),
//         readRuntime: () => runtime,
//         logTag: 'test',
//       );

//       await Future<void>.delayed(Duration.zero);

//       expect(controller.isPeriodicBackupActive, isTrue);

//       controller.stopPeriodicBackup(logTag: 'test');

//       expect(controller.isPeriodicBackupActive, isFalse);
//       expect(backupService.callCount, greaterThanOrEqualTo(0));
//     });

//     test('dispose cancels periodic timer', () async {
//       final storageController = _FakeStorageController(
//         attachmentsPath: '/tmp/store/attachments',
//       );
//       final backupService = _FakeBackupService();
//       final manager = _FakeMainStoreManager()..path = '/tmp/store';
//       final controller = MainStoreBackupController(
//         storageController: storageController,
//       );
//       final runtime = MainStoreRuntime(
//         manager: manager,
//         backupService: backupService,
//         maintenanceService: MainStoreMaintenanceService(),
//       );

//       controller.startPeriodicBackup(
//         interval: const Duration(seconds: 1),
//         scope: BackupScope.full,
//         runImmediately: false,
//         maxBackupsPerStore: 10,
//         readState: () => const DatabaseState(
//           status: DatabaseStatus.open,
//           path: '/tmp/store',
//           name: 'Demo',
//         ),
//         readRuntime: () => runtime,
//         logTag: 'test',
//       );

//       await Future<void>.delayed(Duration.zero);
//       controller.dispose();

//       expect(controller.isPeriodicBackupActive, isFalse);
//     });
//   });
// }

// class _FakeStorageController extends MainStoreStorageController {
//   _FakeStorageController({this.attachmentsPath});

//   final String? attachmentsPath;

//   @override
//   Future<String?> getAttachmentsPath({
//     required DatabaseState state,
//     required MainStoreRuntime runtime,
//     required String logTag,
//   }) async {
//     return attachmentsPath;
//   }
// }

// class _FakeBackupService extends MainStoreBackupService {
//   int callCount = 0;
//   String? lastAttachmentsPath;
//   bool? lastIncludeDatabase;
//   bool? lastIncludeEncryptedFiles;
//   int? lastMaxBackupsPerStore;

//   @override
//   Future<({String backupPath, DateTime createdAt})> createBackup({
//     required String storeDirPath,
//     required String storeName,
//     required bool includeDatabase,
//     required bool includeEncryptedFiles,
//     required bool periodic,
//     String? attachmentsPath,
//     String? outputDirPath,
//     int maxBackupsPerStore = 10,
//   }) async {
//     callCount++;
//     lastAttachmentsPath = attachmentsPath;
//     lastIncludeDatabase = includeDatabase;
//     lastIncludeEncryptedFiles = includeEncryptedFiles;
//     lastMaxBackupsPerStore = maxBackupsPerStore;
//     return (backupPath: '/tmp/backups/demo', createdAt: DateTime(2026, 4, 20));
//   }
// }

// class _FakeMainStoreManager extends MainStoreManager {
//   _FakeMainStoreManager() : super(_FakeDbHistoryService(), _FakeDbKeyService());

//   String? path;

//   @override
//   String? get currentStorePath => path;
// }

// class _FakeDbHistoryService implements DatabaseHistoryService {
//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }

// class _FakeDbKeyService implements DbKeyDerivationService {
//   @override
//   Future<String> derivePragmaKey(
//     String password,
//     String salt, {
//     bool useDeviceKey = false,
//   }) async {
//     return 'pragma-key';
//   }

//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }
