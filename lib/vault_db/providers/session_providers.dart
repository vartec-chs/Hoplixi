import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/db_state.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/services/main_store_manager.dart';

/// Используется для создания [VaultDBManager] (который является фасадом VaultDBFacade).
final vaultDBManagerProvider = FutureProvider<VaultDBManager>((ref) async {
  final dbHistory = await ref.watch(dbHistoryProvider.future);
  final manager = VaultDBManagerFactory(
    dbHistoryService: dbHistory,
    performStoreCleanup: null,
  ).create();
  return manager;
});

/// Стрим-провайдер для реактивного отслеживания активной сессии
final vaultDBSessionStreamProvider = StreamProvider<Session?>((ref) async* {
  final manager = await ref.watch(vaultDBManagerProvider.future);
  yield* manager.sessionStream;
});

/// Провайдер текущей сессии. 100% совместим с прежним FutureProvider<Session>,
/// но зависит исключительно от стрима сессий, а не от UI стейта.
final vaultDBSessionProvider = FutureProvider<Session>((ref) async {
  final sessionAsync = ref.watch(vaultDBSessionStreamProvider);
  final session = sessionAsync.value;
  if (session == null) {
    throw AppError.mainDatabase(
      code: MainDatabaseErrorCode.notInitialized,
      message: 'Сессия не инициализирована',
      timestamp: DateTime.now(),
    );
  }
  return session;
});

/// Провайдер базы данных VaultDB. Реактивно зависит от сессии.
final vaultDBProvider = FutureProvider<VaultDB>((ref) async {
  final session = await ref.watch(vaultDBSessionProvider.future);
  return session.store;
});

/// Провайдер текущего DatabaseState.
final vaultDBStateProvider = FutureProvider<DatabaseState>((ref) async {
  return ref.watch(vaultDBManagerStateProvider.future);
});
