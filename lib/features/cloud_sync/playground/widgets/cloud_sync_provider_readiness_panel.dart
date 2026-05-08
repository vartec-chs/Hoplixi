import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_actions.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_components.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncProviderReadinessPanel extends StatelessWidget {
  const CloudSyncProviderReadinessPanel({
    super.key,
    required this.credentialsAsync,
    required this.tokensAsync,
    this.useGrid = false,
  });

  final AsyncValue<List<AppCredentialEntry>> credentialsAsync;
  final AsyncValue<List<AuthTokenEntry>> tokensAsync;
  final bool useGrid;

  @override
  Widget build(BuildContext context) {
    final providers = CloudSyncProvider.values
        .where((provider) => provider.metadata.supportsAuth)
        .toList(growable: false);
    final credentials = credentialsAsync.value ?? const [];
    final tokens = tokensAsync.value ?? const [];
    final isLoading = credentialsAsync.isLoading || tokensAsync.isLoading;

    return CloudSyncPanel(
      title: 'Провайдеры и готовность',
      icon: LucideIcons.cloud,
      child: useGrid
          ? _ProviderGrid(
              providers: providers,
              credentials: credentials,
              tokens: tokens,
              isLoading: isLoading,
            )
          : Column(
              children: [
                for (var index = 0; index < providers.length; index++) ...[
                  if (index > 0) const Divider(height: 20),
                  _ProviderReadinessRow(
                    provider: providers[index],
                    credentials: credentials,
                    tokens: tokens,
                    isLoading: isLoading,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ProviderGrid extends StatelessWidget {
  const _ProviderGrid({
    required this.providers,
    required this.credentials,
    required this.tokens,
    required this.isLoading,
  });

  final List<CloudSyncProvider> providers;
  final List<AppCredentialEntry> credentials;
  final List<AuthTokenEntry> tokens;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 780 ? 2 : 1;
        final tileWidth =
            (constraints.maxWidth - ((columnCount - 1) * 12)) / columnCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final provider in providers)
              SizedBox(
                width: tileWidth,
                child: _ProviderReadinessCard(
                  provider: provider,
                  credentials: credentials,
                  tokens: tokens,
                  isLoading: isLoading,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProviderReadinessCard extends StatelessWidget {
  const _ProviderReadinessCard({
    required this.provider,
    required this.credentials,
    required this.tokens,
    required this.isLoading,
  });

  final CloudSyncProvider provider;
  final List<AppCredentialEntry> credentials;
  final List<AuthTokenEntry> tokens;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadata = provider.metadata;
    final providerCredentials = _credentialsFor(provider, credentials);
    final providerTokens = _tokensFor(provider, tokens);
    final isReady = providerCredentials.isNotEmpty && providerTokens.isNotEmpty;

    return Material(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.28),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CloudSyncIconBox(
                  icon: CloudSyncProviderLogo(metadata: metadata, size: 22),
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    metadata.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CloudSyncStatusPill(
              label: isLoading
                  ? 'Проверка'
                  : isReady
                  ? 'Готов'
                  : 'Нужна настройка',
              color: isReady ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 10),
            Text(
              '${providerCredentials.length} credentials, ${providerTokens.length} токенов',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.logIn, size: 16),
                    label: const Text('Auth'),
                    onPressed: () => openCloudSyncAuthSheet(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.folderCog, size: 16),
                    label: const Text('API'),
                    onPressed: providerTokens.isEmpty
                        ? null
                        : () => openCloudSyncStorageForProvider(
                            context,
                            provider,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderReadinessRow extends StatelessWidget {
  const _ProviderReadinessRow({
    required this.provider,
    required this.credentials,
    required this.tokens,
    required this.isLoading,
  });

  final CloudSyncProvider provider;
  final List<AppCredentialEntry> credentials;
  final List<AuthTokenEntry> tokens;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadata = provider.metadata;
    final providerCredentials = _credentialsFor(provider, credentials);
    final providerTokens = _tokensFor(provider, tokens);
    final isReady = providerCredentials.isNotEmpty && providerTokens.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CloudSyncIconBox(
          icon: CloudSyncProviderLogo(metadata: metadata, size: 22),
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      metadata.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CloudSyncStatusPill(
                    label: isLoading
                        ? 'Проверка'
                        : isReady
                        ? 'Готов'
                        : 'Нужна настройка',
                    color: isReady ? Colors.green : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${providerCredentials.length} credentials, ${providerTokens.length} токенов',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Авторизовать',
          icon: const Icon(LucideIcons.logIn, size: 18),
          onPressed: () => openCloudSyncAuthSheet(context),
        ),
        IconButton(
          tooltip: 'Storage API',
          icon: const Icon(LucideIcons.folderCog, size: 18),
          onPressed: providerTokens.isEmpty
              ? null
              : () => openCloudSyncStorageForProvider(context, provider),
        ),
      ],
    );
  }
}

List<AppCredentialEntry> _credentialsFor(
  CloudSyncProvider provider,
  List<AppCredentialEntry> credentials,
) {
  return credentials
      .where((entry) => entry.provider == provider)
      .toList(growable: false);
}

List<AuthTokenEntry> _tokensFor(
  CloudSyncProvider provider,
  List<AuthTokenEntry> tokens,
) {
  return tokens
      .where((token) => token.provider == provider)
      .toList(growable: false);
}
