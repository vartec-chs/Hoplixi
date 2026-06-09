import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_cloud_lock_provider.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/features/home/recent_database/controllers/recent_database_history_controller.dart';
import 'package:hoplixi/features/home/recent_database/models/recent_database_card_view_state.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';

import 'recent_database_actions.dart';
import 'recent_database_cloud_sync_info.dart';
import 'recent_database_header.dart';
import 'recent_database_info.dart';

class RecentDatabaseCard extends ConsumerWidget {
  const RecentDatabaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentDbAsync = ref.watch(recentDatabaseProvider);

    return recentDbAsync.when(
      data: (entry) {
        if (entry == null) return const SizedBox.shrink();
        return _RecentDatabaseCardContent(entry: entry);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RecentDatabaseCardContent extends ConsumerWidget {
  const _RecentDatabaseCardContent({required this.entry});

  final DatabaseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final dbState = ref.watch(vaultDBManagerStateProvider).value;
    final lockState = ref.watch(currentStoreCloudLockProvider);
    final manifestAsync = ref.watch(vaultDBManifestProvider);

    final viewState = RecentDatabaseCardViewState.from(
      entry: entry,
      dbState: dbState,
      lockState: lockState,
      manifestAsync: manifestAsync,
    );

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecentDatabaseHeader(
              entry: entry,
              onDelete: () => ref
                  .read(recentDatabaseHistoryControllerProvider)
                  .deleteFromHistory(context, entry),
            ),
            const SizedBox(height: 8),
            RecentDatabaseInfo(entry: entry),
            if (viewState.syncProvider != null) ...[
              const SizedBox(height: 8),
              RecentDatabaseCloudSyncInfo(
                syncProvider: viewState.syncProvider!,
              ),
            ],
            const SizedBox(height: 12),
            RecentDatabaseActions(entry: entry, viewState: viewState),
          ],
        ),
      ),
    );
  }
}
