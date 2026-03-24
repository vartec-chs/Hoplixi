import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/cloud_sync_conflict_dialog.dart';
import 'package:hoplixi/shared/ui/button.dart';


class CloudSyncSettingsPage extends ConsumerStatefulWidget {
  const CloudSyncSettingsPage({super.key});

  @override
  ConsumerState<CloudSyncSettingsPage> createState() =>
      _CloudSyncSettingsPageState();
}

class _CloudSyncSettingsPageState extends ConsumerState<CloudSyncSettingsPage> {
  CloudSyncProvider? _selectedProvider;
  String? _selectedTokenId;
  SnapshotSyncConflict? _lastShownConflict;
  ProviderSubscription<AsyncValue<StoreSyncStatus>>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _syncSubscription = ref.listenManual<AsyncValue<StoreSyncStatus>>(
      currentStoreSyncProvider,
      (previous, next) {
        next.whenData((status) async {
          final conflict = status.pendingConflict;
          if (conflict == null || identical(conflict, _lastShownConflict)) {
            return;
          }
          _lastShownConflict = conflict;
          final resolution = await showCloudSyncConflictDialog(
            context,
            conflict: conflict,
          );
          if (!mounted || resolution == null) {
            return;
          }
          if (resolution == SnapshotConflictResolution.uploadLocal) {
            await _runAction(
              () => ref
                  .read(currentStoreSyncProvider.notifier)
                  .resolveConflictWithUpload(),
            );
          } else {
            await _runAction(
              () => ref
                  .read(currentStoreSyncProvider.notifier)
                  .resolveConflictWithDownload(),
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _syncSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(currentStoreSyncProvider);
    final tokensAsync = ref.watch(authTokensProvider);

    return syncState.when(
      data: (status) {
        final tokens = tokensAsync.value ?? const <AuthTokenEntry>[];
        final availableProviders = tokens
            .map((token) => token.provider)
            .toSet()
            .toList(growable: false);
        final effectiveProvider =
            _selectedProvider ??
            status.binding?.provider ??
            status.token?.provider ??
            (availableProviders.isNotEmpty ? availableProviders.first : null);
        final providerTokens = effectiveProvider == null
            ? const <AuthTokenEntry>[]
            : tokens
                  .where((token) => token.provider == effectiveProvider)
                  .toList(growable: false);
        final effectiveTokenId =
            providerTokens.any(
                  (token) =>
                      token.id ==
                      (_selectedTokenId ?? status.binding?.tokenId ?? status.token?.id),
                )
            ? (_selectedTokenId ?? status.binding?.tokenId ?? status.token?.id)
            : (providerTokens.isNotEmpty ? providerTokens.first.id : null);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cloud Sync',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                status.binding == null
                    ? 'Подключите OAuth-токен для ручной snapshot-синхронизации текущего хранилища.'
                    : 'Текущий store привязан к ${status.binding!.provider.metadata.displayName}.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CloudSyncProvider>(
                initialValue: effectiveProvider,
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
                onChanged: (value) {
                  setState(() {
                    _selectedProvider = value;
                    _selectedTokenId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: effectiveTokenId,
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
                    : (value) {
                        setState(() {
                          _selectedTokenId = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              _StatusCard(
                status: status,
                token: status.token,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SmoothButton(
                    label: providerTokens.isEmpty ? 'Authorize' : 'Connect',
                    onPressed: () async {
                      if (providerTokens.isEmpty) {
                        await showCloudSyncAuthSheet(
                          context: context,
                          ref: ref,
                          previousRoute: GoRouterState.of(context).uri.toString(),
                          initialProvider: effectiveProvider,
                        );
                        ref.invalidate(authTokensProvider);
                        await ref.read(authTokensProvider.notifier).reload();
                        if (mounted) {
                          await ref
                              .read(currentStoreSyncProvider.notifier)
                              .loadStatus();
                        }
                        return;
                      }
                      final selectedTokenId = effectiveTokenId;
                      if (selectedTokenId == null) {
                        Toaster.error(
                          title: 'Cloud Sync',
                          description: 'Выберите OAuth-токен для подключения.',
                        );
                        return;
                      }
                      await _runAction(
                        () => ref
                            .read(currentStoreSyncProvider.notifier)
                            .connect(selectedTokenId),
                      );
                    },
                  ),
                  SmoothButton(
                    label: 'Sync now',
                    onPressed: status.binding == null
                        ? null
                        : () => _runAction(
                              () => ref
                                  .read(currentStoreSyncProvider.notifier)
                                  .syncNow(),
                            ),
                  ),
                  SmoothButton(
                    label: 'Upload local',
                    onPressed: status.binding == null
                        ? null
                        : () => _runAction(
                              () => ref
                                  .read(currentStoreSyncProvider.notifier)
                                  .resolveConflictWithUpload(),
                            ),
                  ),
                  SmoothButton(
                    label: 'Download remote',
                    onPressed: status.binding == null
                        ? null
                        : () => _runAction(
                              () => ref
                                  .read(currentStoreSyncProvider.notifier)
                                  .resolveConflictWithDownload(),
                            ),
                  ),
                  SmoothButton(
                    label: 'Disconnect',
                    onPressed: status.binding == null
                        ? null
                        : () => _runAction(
                              () => ref
                                  .read(currentStoreSyncProvider.notifier)
                                  .disconnect(),
                            ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Cloud sync error: $error'),
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      final status = ref.read(currentStoreSyncProvider).value;
      final description = switch (status?.lastResultType) {
        SnapshotSyncResultType.uploaded => 'Локальная snapshot-версия загружена.',
        SnapshotSyncResultType.downloaded =>
          status?.requiresUnlockToApply == true
              ? 'Remote snapshot загружен. Разблокируйте хранилище, чтобы продолжить работу.'
              : 'Remote snapshot загружен.',
        SnapshotSyncResultType.noChanges => 'Локальная и удалённая версии уже совпадают.',
        SnapshotSyncResultType.conflict => 'Обнаружен конфликт версий.',
        _ => 'Операция выполнена.',
      };
      Toaster.success(title: 'Cloud Sync', description: description);
    } catch (error) {
      if (!mounted) {
        return;
      }
      Toaster.error(title: 'Cloud Sync', description: error.toString());
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.token});

  final StoreSyncStatus status;
  final AuthTokenEntry? token;

  @override
  Widget build(BuildContext context) {
    final localManifest = status.localManifest;
    final remoteManifest = status.remoteManifest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Store: ${status.storeName ?? '-'}'),
            const SizedBox(height: 8),
            Text('Provider: ${status.binding?.provider.metadata.displayName ?? '-'}'),
            Text('Account: ${token?.displayLabel ?? '-'}'),
            const SizedBox(height: 8),
            Text('Local revision: ${localManifest?.revision ?? '-'}'),
            Text('Remote revision: ${remoteManifest?.revision ?? '-'}'),
            Text('Compare: ${status.compareResult.name}'),
            Text(
              'Last synced: ${localManifest?.sync?.syncedAt?.toUtc().toIso8601String() ?? '-'}',
            ),
            if (status.requiresUnlockToApply) ...[
              const SizedBox(height: 8),
              const Text(
                'Remote snapshot already written to disk. Unlock the store to continue.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
