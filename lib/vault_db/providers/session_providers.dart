import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/providers/vault_ui_state_provider.dart';

final vaultDBSessionProvider = Provider<Session?>((ref) {
  final dbState = ref.watch(vaultDBManagerStateProvider);

  return dbState.maybeWhen(
    data: (state) => state.isOpen
        ? ref.read(vaultDBManagerStateProvider.notifier).currentSession
        : null,
    orElse: () => null,
  );
});

/// Провайдер базы данных VaultDB. Реактивно зависит от сессии.
final vaultDBProvider = FutureProvider<VaultDB?>((ref) async {
  final session = ref.watch(vaultDBSessionProvider);
  if (session == null) {
    return null;
  }
  return session.api.db;
});

final requiredVaultDBSessionProvider = Provider<Session>((ref) {
  final session = ref.watch(vaultDBSessionProvider);

  if (session == null) {
    throw StateError('Vault database is not open');
  }

  return session;
});

final requiredVaultDBProvider = Provider<VaultDB>((ref) {
  final session = ref.watch(requiredVaultDBSessionProvider);
  return session.api.db;
});
