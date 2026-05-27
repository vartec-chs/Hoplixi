import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/providers/session_providers.dart';

/// Реактивный Эффект Очистки хранилища.
/// Слушает открытие сессии и асинхронно запускает фоновую очистку.
final vaultCleanupEffectProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Session?>>(vaultDBSessionStreamProvider, (
    previous,
    next,
  ) {
    final session = next.value;
    if (session == null) return;

    final prevSession = previous?.value;
    if (prevSession?.storeDirectoryPath == session.storeDirectoryPath) return;

    logInfo(
      'Session opened, scheduling background store cleanup...',
      tag: 'VaultCleanupEffect',
    );
    scheduleMicrotask(() async {
      try {
        final cleanup = await ref.read(performStoreCleanupProvider.future);
        await cleanup(ignoreInterval: false);
        logInfo(
          'Background store cleanup completed successfully',
          tag: 'VaultCleanupEffect',
        );
      } catch (error, stackTrace) {
        logWarning(
          'Failed to perform store cleanup in background',
          tag: 'VaultCleanupEffect',
          data: {
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
      }
    });
  });
});
