import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class RecentDatabaseCloudSyncInfo extends StatelessWidget {
  const RecentDatabaseCloudSyncInfo({super.key, required this.syncProvider});

  final CloudSyncProvider syncProvider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CloudSyncProviderLogo(
            metadata: syncProvider.metadata,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Подключен Cloud Sync: ${syncProvider.metadata.displayName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
