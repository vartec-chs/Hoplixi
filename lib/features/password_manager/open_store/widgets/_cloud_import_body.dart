part of '../open_store_cloud_import_screen.dart';

class _CloudImportBody extends ConsumerStatefulWidget {
  const _CloudImportBody({required this.state});

  final OpenStoreCloudImportState state;

  @override
  ConsumerState<_CloudImportBody> createState() => _CloudImportBodyState();
}

class _CloudImportBodyState extends ConsumerState<_CloudImportBody> {
  String? _deletingRemoteStoreUuid;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(openStoreCloudImportProvider.notifier);
    final selectedProvider = state.selectedCloudProvider;
    final providerTokens = selectedProvider == null
        ? const <AuthTokenEntry>[]
        : (state.cloudTokensByProvider[selectedProvider] ??
              const <AuthTokenEntry>[]);
    final selectedToken = providerTokens
        .where((token) => token.id == state.selectedCloudTokenId)
        .firstOrNull;
    final hasDeleteInProgress = _deletingRemoteStoreUuid != null;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<CloudSyncProvider>(
                  initialValue: selectedProvider,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Провайдер',
                  ),
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
                const SizedBox(height: 12),
                Text(
                  'Шаг 2. Авторизуйте аккаунт или выберите OAuth токен',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: state.selectedCloudTokenId,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'OAuth токен',
                  ),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SmoothButton(
                      label: providerTokens.isEmpty
                          ? 'Авторизоваться'
                          : 'Обновить список',
                      onPressed: hasDeleteInProgress
                          ? null
                          : () async {
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
                                  container: ProviderScope.containerOf(
                                    context,
                                    listen: false,
                                  ),
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
                      final isDeleting =
                          _deletingRemoteStoreUuid == entry.storeUuid;
                      return _RemoteSnapshotCard(
                        entry: entry,
                        provider: selectedProvider!,
                        accountLabel: selectedToken?.displayLabel ?? '-',
                        isDownloading:
                            state.downloadingRemoteStoreUuid == entry.storeUuid,
                        isDeleting: isDeleting,
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
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Удалить snapshot из облака'),
                              content: Text(
                                'Удалить remote snapshot "${entry.storeName}" из ${selectedProvider.metadata.displayName}? '
                                'Операция удалит данные store из облака и скроет snapshot из cloud manifest.',
                              ),
                              actions: [
                                SmoothButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  label: 'Отмена',
                                  type: SmoothButtonType.text,
                                ),
                                SmoothButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  label: 'Удалить',
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !mounted) {
                            return;
                          }

                          setState(() {
                            _deletingRemoteStoreUuid = entry.storeUuid;
                          });
                          try {
                            final deleted = await notifier.deleteRemoteSnapshot(
                              entry,
                            );
                            if (!mounted || !deleted) {
                              return;
                            }

                            Toaster.success(
                              context: context,
                              title: 'Cloud Sync',
                              description:
                                  'Snapshot "${entry.storeName}" удалён из облака.',
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _deletingRemoteStoreUuid = null;
                              });
                            }
                          }
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

extension _IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
