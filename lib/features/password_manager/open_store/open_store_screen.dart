import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_form_provider.dart';
import 'package:hoplixi/features/password_manager/open_store/widgets/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';

class OpenStoreScreen extends ConsumerStatefulWidget {
  const OpenStoreScreen({super.key});

  @override
  ConsumerState<OpenStoreScreen> createState() => _OpenStoreScreenState();
}

class _OpenStoreScreenState extends ConsumerState<OpenStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
    });
  }

  void _showPasswordFormDialog(OpenStoreState state) {
    final notifier = ref.read(openStoreFormProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: !state.isOpening,
        builder: (dialogContext) => Dialog(
          insetPadding: EdgeInsets.all(screenPaddingValue),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: PasswordForm(
              onSuccess: () => _handleOpenSuccess(dialogContext),
              onCancel: () {
                Navigator.of(dialogContext).pop();
                notifier.cancelSelection();
              },
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !state.isOpening,
      enableDrag: !state.isOpening,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: PasswordForm(
          onSuccess: () => _handleOpenSuccess(sheetContext),
          onCancel: () {
            Navigator.of(sheetContext).pop();
            notifier.cancelSelection();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(openStoreFormProvider);
    final notifier = ref.read(openStoreFormProvider.notifier);

    ref.listen<AsyncValue<OpenStoreState>>(openStoreFormProvider, (
      previous,
      next,
    ) {
      next.whenData((state) async {
        if (state.selectedStorage != null &&
            previous?.value?.selectedStorage != state.selectedStorage) {
          _showPasswordFormDialog(state);
        }

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

        if (!mounted) {
          return;
        }

        final didBind = await notifier.resolvePendingImportedStoreBinding(
          bind: shouldBind == true,
        );
        if (!mounted) {
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
        title: const Text('Открыть хранилище'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref
                .read(titlebarStateProvider.notifier)
                .setBackgroundTransparent(true);
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: asyncState.isLoading
                ? null
                : () async {
                    await notifier.loadStorages();
                    if (!mounted) {
                      return;
                    }
                    await notifier.reloadCloudOptions();
                  },
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: asyncState.when(
        data: (state) => _buildBody(context, state, notifier),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Инициализация...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка инициализации',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SmoothButton(
                onPressed: () => ref.invalidate(openStoreFormProvider),
                icon: const Icon(Icons.refresh),
                label: 'Повторить',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OpenStoreState state,
    OpenStoreFormNotifier notifier,
  ) {
    final regularStorages = state.storages
        .where((storage) => !storage.path.contains('_backup_'))
        .toList(growable: false);
    final backupStorages = state.storages
        .where((storage) => storage.path.contains('_backup_'))
        .toList(growable: false);

    if (state.isLoading && state.storages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка хранилищ...'),
          ],
        ),
      );
    }

    if (state.error != null && state.storages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SmoothButton(
              onPressed: () => notifier.loadStorages(),
              icon: const Icon(Icons.refresh),
              label: 'Повторить',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.error != null) _buildErrorBanner(context, state.error!),
        _buildCloudSection(context, state, notifier),
        const Divider(height: 1),
        Expanded(
          child: backupStorages.isEmpty
              ? StorageList(
                  storages: regularStorages,
                  selectedStorage: state.selectedStorage,
                  onStorageSelected: notifier.selectStorage,
                  onStorageDelete: (storage) =>
                      _handleDeleteStorage(storage, ref),
                )
              : Column(
                  children: [
                    Expanded(
                      child: StorageList(
                        storages: regularStorages,
                        selectedStorage: state.selectedStorage,
                        onStorageSelected: notifier.selectStorage,
                        onStorageDelete: (storage) =>
                            _handleDeleteStorage(storage, ref),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Бэкапы',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: StorageList(
                              storages: backupStorages,
                              selectedStorage: state.selectedStorage,
                              onStorageSelected: notifier.selectStorage,
                              onStorageDelete: (storage) =>
                                  _handleDeleteBackup(storage, ref),
                              showCreateButton: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCloudSection(
    BuildContext context,
    OpenStoreState state,
    OpenStoreFormNotifier notifier,
  ) {
    final selectedProvider = state.selectedCloudProvider;
    final providerTokens = selectedProvider == null
        ? const <AuthTokenEntry>[]
        : (state.cloudTokensByProvider[selectedProvider] ??
              const <AuthTokenEntry>[]);
    final selectedToken = providerTokens
        .where((token) => token.id == state.selectedCloudTokenId)
        .firstOrNull;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Скачать из Cloud Sync',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите OAuth токен, посмотрите доступные remote snapshots и скачайте нужный store в локальное хранилище.',
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
                onChanged: (value) => notifier.selectCloudProvider(value),
              ),
              const SizedBox(height: 12),
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
                    : (value) => notifier.selectCloudToken(value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SmoothButton(
                    label: providerTokens.isEmpty ? 'Authorize' : 'Обновить',
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
                        if (!mounted) {
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
              if (state.remoteSnapshotsError != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(context, state.remoteSnapshotsError!),
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
                _buildPlaceholder(
                  context,
                  icon: Icons.cloud_queue_outlined,
                  text: providerTokens.isEmpty
                      ? 'Добавьте OAuth токен для выбранного провайдера.'
                      : 'Выберите OAuth токен, чтобы загрузить список remote stores.',
                )
              else if (state.remoteSnapshots.isEmpty)
                _buildPlaceholder(
                  context,
                  icon: Icons.inventory_2_outlined,
                  text:
                      'В cloud_manifest нет доступных snapshot stores для выбранного токена.',
                )
              else
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    itemCount: state.remoteSnapshots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = state.remoteSnapshots[index];
                      return _buildRemoteSnapshotCard(
                        context,
                        entry: entry,
                        provider: selectedProvider!,
                        accountLabel: selectedToken?.displayLabel ?? '-',
                        isDownloading:
                            state.downloadingRemoteStoreUuid == entry.storeUuid,
                        onDownload: () async {
                          final result = await notifier.importRemoteSnapshot(
                            entry,
                          );
                          if (!mounted || result == null) {
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteSnapshotCard(
    BuildContext context, {
    required CloudManifestStoreEntry entry,
    required CloudSyncProvider provider,
    required String accountLabel,
    required bool isDownloading,
    required VoidCallback onDownload,
  }) {
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

  Widget _buildPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
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

  Widget _buildErrorBanner(BuildContext context, String message) {
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

  Future<void> _handleDeleteStorage(StorageInfo storage, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить хранилище'),
        content: Text(
          'Удалить хранилище "${storage.name}" с диска?\n\n'
          'Это действие необратимо! Все данные будут удалены безвозвратно.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final notifier = ref.read(openStoreFormProvider.notifier);
    final success = await notifier.deleteStorage(storage.path);
    if (!mounted) {
      return;
    }

    if (success) {
      Toaster.success(
        context: context,
        title: 'Успех',
        description: 'Хранилище удалено с диска',
      );
      return;
    }

    Toaster.error(
      context: context,
      title: 'Ошибка',
      description: 'Не удалось удалить хранилище',
    );
  }

  Future<void> _handleDeleteBackup(StorageInfo storage, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить бэкап'),
        content: Text(
          'Удалить бэкап "${storage.name}" с диска?\n\n'
          'Это действие необратимо.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final notifier = ref.read(openStoreFormProvider.notifier);
    final success = await notifier.deleteStorage(storage.path);
    if (!mounted) {
      return;
    }

    if (success) {
      Toaster.success(
        context: context,
        title: 'Успех',
        description: 'Бэкап удалён с диска',
      );
      return;
    }

    Toaster.error(
      context: context,
      title: 'Ошибка',
      description: 'Не удалось удалить бэкап',
    );
  }

  void _handleOpenSuccess(BuildContext dialogContext) {
    if (!mounted) {
      return;
    }

    Navigator.of(dialogContext).pop();
    Toaster.success(
      context: context,
      title: 'Успешно',
      description: 'Хранилище открыто',
    );
    context.go(AppRoutesPaths.home);
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
  }

  String _resolvePreviousRoute(BuildContext context) {
    try {
      return GoRouter.of(context).state.uri.toString();
    } catch (_) {
      return AppRoutesPaths.openStore;
    }
  }
}

extension _IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
