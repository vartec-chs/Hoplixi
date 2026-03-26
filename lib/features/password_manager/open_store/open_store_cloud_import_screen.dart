import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_form_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

class OpenStoreCloudImportScreen extends ConsumerWidget {
  const OpenStoreCloudImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(openStoreFormProvider);
    final notifier = ref.read(openStoreFormProvider.notifier);

    ref.listen<AsyncValue<OpenStoreState>>(openStoreFormProvider, (
      previous,
      next,
    ) {
      next.whenData((state) async {
        final pendingBinding = state.pendingImportedStoreBinding;
        final previousBinding = previous?.value?.pendingImportedStoreBinding;
        if (pendingBinding == null ||
            identical(pendingBinding, previousBinding)) {
          return;
        }

        final shouldBind = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Привязать к cloud sync'),
            content: Text(pendingBinding.promptDescription),
            actions: [
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                label: 'Нет',
                type: SmoothButtonType.text,
              ),
              SmoothButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                label: 'Привязать',
              ),
            ],
          ),
        );

        final didBind = await notifier.resolvePendingImportedStoreBinding(
          bind: shouldBind == true,
        );
        if (!context.mounted) {
          return;
        }

        if (didBind) {
          Toaster.success(
            context: context,
            title: 'Cloud Sync',
            description: 'Локальная копия привязана к облачному store.',
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт из Cloud Sync'),
        actions: [
          IconButton(
            onPressed: asyncState.isLoading
                ? null
                : () async => notifier.reloadCloudOptions(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => _CloudImportBody(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Не удалось открыть экран импорта',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudImportBody extends ConsumerWidget {
  const _CloudImportBody({required this.state});

  final OpenStoreState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(openStoreFormProvider.notifier);
    final selectedProvider = state.selectedCloudProvider;
    final providerTokens = selectedProvider == null
        ? const <AuthTokenEntry>[]
        : (state.cloudTokensByProvider[selectedProvider] ??
              const <AuthTokenEntry>[]);
    final selectedToken = providerTokens
        .where((token) => token.id == state.selectedCloudTokenId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Шаг 1. Выберите облачный сервис',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Сначала выберите провайдера. Затем авторизуйте аккаунт или выберите уже сохранённый OAuth токен.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CloudSyncProvider>(
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(labelText: 'Провайдер'),
                  items: CloudSyncProvider.values
                      .where((provider) => provider != CloudSyncProvider.other)
                      .map(
                        (provider) => DropdownMenuItem<CloudSyncProvider>(
                          value: provider,
                          child: Text(provider.metadata.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: notifier.selectCloudProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  'Шаг 2. Авторизуйте аккаунт или выберите OAuth токен',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: state.selectedCloudTokenId,
                  decoration: const InputDecoration(labelText: 'OAuth token'),
                  items: providerTokens
                      .map(
                        (token) => DropdownMenuItem<String>(
                          value: token.id,
                          child: Text(token.displayLabel),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: providerTokens.isEmpty
                      ? null
                      : notifier.selectCloudToken,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SmoothButton(
                      label: providerTokens.isEmpty
                          ? 'Авторизоваться'
                          : 'Обновить список',
                      onPressed: () async {
                        if (selectedProvider == null) {
                          Toaster.error(
                            context: context,
                            title: 'Cloud Sync',
                            description: 'Сначала выберите провайдера.',
                          );
                          return;
                        }

                        if (providerTokens.isEmpty) {
                          await showCloudSyncAuthSheet(
                            context: context,
                            ref: ref,
                            previousRoute: _resolvePreviousRoute(context),
                            initialProvider: selectedProvider,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          await notifier.reloadCloudOptions();
                          return;
                        }

                        if (state.selectedCloudTokenId != null) {
                          await notifier.selectCloudToken(
                            state.selectedCloudTokenId,
                          );
                        }
                      },
                    ),
                    if (selectedToken != null)
                      Chip(
                        avatar: const Icon(Icons.cloud_done_outlined, size: 18),
                        label: Text(
                          '${selectedProvider?.metadata.displayName ?? '-'} · ${selectedToken.displayLabel}',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Шаг 3. Выберите удалённый snapshot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Список строится по `cloud_manifest`. Скачанный store появится в локальном списке хранилищ на экране открытия.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (state.remoteSnapshotsError != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: state.remoteSnapshotsError!),
                ],
                const SizedBox(height: 16),
                if (state.isLoadingRemoteSnapshots)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.selectedCloudTokenId == null)
                  _Placeholder(
                    icon: Icons.cloud_queue_outlined,
                    text: providerTokens.isEmpty
                        ? 'Добавьте OAuth токен для выбранного провайдера.'
                        : 'Выберите OAuth токен, чтобы загрузить список remote stores.',
                  )
                else if (state.remoteSnapshots.isEmpty)
                  const _Placeholder(
                    icon: Icons.inventory_2_outlined,
                    text:
                        'В cloud_manifest нет доступных snapshot stores для выбранного токена.',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.remoteSnapshots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = state.remoteSnapshots[index];
                      return _RemoteSnapshotCard(
                        entry: entry,
                        provider: selectedProvider!,
                        accountLabel: selectedToken?.displayLabel ?? '-',
                        isDownloading:
                            state.downloadingRemoteStoreUuid == entry.storeUuid,
                        onDownload: () async {
                          final result = await notifier.importRemoteSnapshot(
                            entry,
                          );
                          if (!context.mounted || result == null) {
                            return;
                          }

                          Toaster.success(
                            context: context,
                            title: 'Cloud Sync',
                            description:
                                'Snapshot "${entry.storeName}" скачан в локальное хранилище.',
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _resolvePreviousRoute(BuildContext context) {
    try {
      return GoRouter.of(context).state.uri.toString();
    } catch (_) {
      return AppRoutesPaths.openStoreCloudImport;
    }
  }
}

class _RemoteSnapshotCard extends StatelessWidget {
  const _RemoteSnapshotCard({
    required this.entry,
    required this.provider,
    required this.accountLabel,
    required this.isDownloading,
    required this.onDownload,
  });

  final CloudManifestStoreEntry entry;
  final CloudSyncProvider provider;
  final String accountLabel;
  final bool isDownloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final updatedAt = entry.updatedAt.toLocal();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(provider.metadata.icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.storeName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${provider.metadata.displayName} · $accountLabel'),
                  const SizedBox(height: 4),
                  Text('Revision: ${entry.revision}'),
                  Text(
                    'Updated: ${updatedAt.day.toString().padLeft(2, '0')}.${updatedAt.month.toString().padLeft(2, '0')}.${updatedAt.year} '
                    '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SmoothButton(
              label: 'Скачать',
              onPressed: isDownloading ? null : onDownload,
              loading: isDownloading,
              icon: const Icon(Icons.download_outlined),
              size: SmoothButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
