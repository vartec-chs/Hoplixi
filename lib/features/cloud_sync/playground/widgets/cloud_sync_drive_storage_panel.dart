import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_actions.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_components.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncDriveStoragePanel extends StatelessWidget {
  const CloudSyncDriveStoragePanel({
    super.key,
    required this.tokensAsync,
    this.useGrid = false,
  });

  final AsyncValue<List<AuthTokenEntry>> tokensAsync;
  final bool useGrid;

  @override
  Widget build(BuildContext context) {
    final tokens = tokensAsync.value ?? const [];
    final driveProviders = CloudSyncProvider.values
        .where((provider) => provider != CloudSyncProvider.other)
        .toList(growable: false);

    return CloudSyncPanel(
      title: 'Drive Storage API',
      icon: LucideIcons.hardDrive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Дополнительный рабочий экран для файлового API: папки, upload/download, copy/move/delete. Откройте provider с готовым токеном.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          useGrid
              ? _DriveProviderGrid(
                  providers: driveProviders,
                  tokens: tokens,
                  isLoading: tokensAsync.isLoading,
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final provider in driveProviders)
                      _DriveProviderChip(
                        provider: provider,
                        tokenCount: _tokenCountFor(provider, tokens),
                        isLoading: tokensAsync.isLoading,
                      ),
                  ],
                ),
          const SizedBox(height: 14),
          SmoothButton(
            label: 'Открыть Storage API',
            type: SmoothButtonType.tonal,
            icon: const Icon(LucideIcons.folderOpen, size: 18),
            onPressed: () => openCloudSyncStorage(context),
          ),
        ],
      ),
    );
  }
}

class _DriveProviderGrid extends StatelessWidget {
  const _DriveProviderGrid({
    required this.providers,
    required this.tokens,
    required this.isLoading,
  });

  final List<CloudSyncProvider> providers;
  final List<AuthTokenEntry> tokens;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 820 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - ((columnCount - 1) * 10)) / columnCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final provider in providers)
              SizedBox(
                width: tileWidth,
                child: _DriveProviderCard(
                  provider: provider,
                  tokenCount: _tokenCountFor(provider, tokens),
                  isLoading: isLoading,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DriveProviderCard extends StatelessWidget {
  const _DriveProviderCard({
    required this.provider,
    required this.tokenCount,
    required this.isLoading,
  });

  final CloudSyncProvider provider;
  final int tokenCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadata = provider.metadata;

    return Material(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.28),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: tokenCount == 0
            ? null
            : () => openCloudSyncStorageForProvider(context, provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metadata.icon, size: 22, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                metadata.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLoading ? 'Проверка' : '$tokenCount токенов',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriveProviderChip extends StatelessWidget {
  const _DriveProviderChip({
    required this.provider,
    required this.tokenCount,
    required this.isLoading,
  });

  final CloudSyncProvider provider;
  final int tokenCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final metadata = provider.metadata;

    return ActionChip(
      avatar: Icon(metadata.icon, size: 18),
      label: Text(
        isLoading
            ? metadata.displayName
            : '${metadata.displayName} · $tokenCount',
      ),
      onPressed: tokenCount == 0
          ? null
          : () => openCloudSyncStorageForProvider(context, provider),
    );
  }
}

int _tokenCountFor(CloudSyncProvider provider, List<AuthTokenEntry> tokens) {
  return tokens.where((token) => token.provider == provider).length;
}
