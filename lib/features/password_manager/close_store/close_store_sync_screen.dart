import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/snapshot_sync_progress_card.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';

class CloseStoreSyncScreen extends ConsumerWidget {
  const CloseStoreSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(mainStoreProvider).value;
    final syncStatus =
        ref.watch(closeStoreSyncStatusProvider) ??
        ref.watch(currentStoreSyncProvider).value;
    final syncProgress = syncStatus?.syncProgress;
    final requiresUnlockToApply = syncStatus?.requiresUnlockToApply ?? false;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Закрытие хранилища',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requiresUnlockToApply
                        ? 'Удалённый snapshot уже применён локально. Экран закроется автоматически после завершения сценария закрытия.'
                        : 'Идёт синхронизация изменений перед закрытием. Это окно закроется автоматически.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (dbState?.name != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      dbState!.name!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (dbState?.path != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dbState!.path!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (syncProgress != null)
                    SnapshotSyncProgressCard(progress: syncProgress)
                  else if (requiresUnlockToApply)
                    const SnapshotSyncPendingApplyCard()
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
