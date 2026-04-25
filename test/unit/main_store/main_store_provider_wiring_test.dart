// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hoplixi/db_core/main_store_manager.dart';
// import 'package:hoplixi/db_core/models/db_state.dart';
// import 'package:hoplixi/db_core/provider/main_store_provider.dart';
// import 'package:hoplixi/db_core/provider/main_store_runtime_provider.dart';
// import 'package:hoplixi/db_core/services/db_history_services.dart';
// import 'package:hoplixi/db_core/services/db_key_derivation_service.dart';
// import 'package:hoplixi/db_core/services/main_store_backup_service.dart';
// import 'package:hoplixi/db_core/services/main_store_maintenance_service.dart';

// void main() {
//   test(
//     'mainStoreManagerProvider resolves manager from runtime when store is open',
//     () async {
//       final manager = _FakeMainStoreManager()..path = '/tmp/store';
//       final runtime = MainStoreRuntime(
//         manager: manager,
//         backupService: MainStoreBackupService(),
//         maintenanceService: MainStoreMaintenanceService(),
//       );

//       final container = ProviderContainer.test(
//         overrides: [
//           mainStoreRuntimeProvider.overrideWith((ref) async => runtime),
//           mainStoreProvider.overrideWith(
//             () => _FakeMainStoreNotifier(
//               const DatabaseState(
//                 status: DatabaseStatus.open,
//                 path: '/tmp/store',
//                 name: 'Demo',
//               ),
//             ),
//           ),
//         ],
//       );
//       addTearDown(container.dispose);

//       final resolved = await container.read(mainStoreManagerProvider.future);

//       expect(identical(resolved, manager), isTrue);
//     },
//   );

//   test(
//     'mainStoreManagerProvider returns null when store is not open',
//     () async {
//       final manager = _FakeMainStoreManager()..path = '/tmp/store';
//       final runtime = MainStoreRuntime(
//         manager: manager,
//         backupService: MainStoreBackupService(),
//         maintenanceService: MainStoreMaintenanceService(),
//       );

//       final container = ProviderContainer.test(
//         overrides: [
//           mainStoreRuntimeProvider.overrideWith((ref) async => runtime),
//           mainStoreProvider.overrideWith(
//             () => _FakeMainStoreNotifier(
//               const DatabaseState(status: DatabaseStatus.locked),
//             ),
//           ),
//         ],
//       );
//       addTearDown(container.dispose);

//       final resolved = await container.read(mainStoreManagerProvider.future);

//       expect(resolved, isNull);
//     },
//   );
// }

// class _FakeMainStoreNotifier extends MainStoreAsyncNotifier {
//   _FakeMainStoreNotifier(this._state);

//   final DatabaseState _state;

//   @override
//   Future<DatabaseState> build() async => _state;
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
