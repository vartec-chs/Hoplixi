import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/snapshot_sync_progress_card.dart';
import 'package:hoplixi/main_db/providers/db_history_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/main_db/services/vault_key_file_service.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class LockStoreScreen extends ConsumerStatefulWidget {
  const LockStoreScreen({super.key});

  @override
  ConsumerState<LockStoreScreen> createState() => _LockStoreScreenState();
}

class _LockStoreScreenState extends ConsumerState<LockStoreScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _hasSavedPassword = false;

  @override
  void initState() {
    super.initState();
    _checkSavedPassword();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedPassword() async {
    final dbState = ref.read(mainStoreProvider).value;
    if (dbState?.path == null) return;

    final historyService = await ref.read(dbHistoryProvider.future);
    final entry = await historyService.getByPath(dbState!.path!);
    final savedPassword = entry?.savePassword == true
        ? await historyService.getSavedPasswordByPath(dbState.path!)
        : null;

    if (entry != null && savedPassword != null) {
      setState(() {
        _hasSavedPassword = true;
        _passwordController.text = savedPassword;
      });
    }
  }

  Future<void> _unlock() async {
    final syncState = ref.read(currentStoreSyncProvider);
    final isSyncStatusLoading = syncState.isLoading && syncState.value == null;
    final isApplyingRemoteUpdate =
        syncState.value?.isApplyingRemoteUpdate ?? false;
    final syncActivity =
        syncState.value?.syncActivity ?? StoreSyncActivity.idle;
    final isSyncInProgress =
        (syncState.value?.isSyncInProgress ?? false) ||
        syncActivity != StoreSyncActivity.idle;
    if (isSyncStatusLoading || isSyncInProgress || isApplyingRemoteUpdate) {
      return;
    }

    if (_passwordController.text.isEmpty && !_hasSavedPassword) {
      Toaster.error(title: 'Ошибка', description: 'Введите пароль');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbState = await ref.read(mainStoreProvider.future);
      final storePath = dbState.path;
      VaultKeyFile? keyFile;
      if (storePath != null) {
        final manifest = await StoreManifestService.readFrom(storePath);
        if (manifest?.useKeyFile == true) {
          if (keyFile == null) {
            final result = await const VaultKeyFileService().pickAndRead();
            keyFile = result.fold((value) => value, (error) {
              if (mounted) {
                Toaster.error(title: 'Ошибка key file', description: error.message);
              }
              return null;
            });
          }
          if (keyFile == null) {
            return;
          }
          if (keyFile.id != manifest!.keyFileId) {
            if (mounted) {
              Toaster.error(
                title: 'Неверный key file',
                description: 'Выбранный JSON key file не подходит для хранилища',
              );
            }
            return;
          }
        }
      }

      final success = await ref.read(mainStoreProvider.notifier).unlockStore(
            _passwordController.text,
            keyFileId: keyFile?.id,
            keyFileSecret: keyFile?.secret,
          );

      if (success) {
        if (mounted) {
          context.go(AppRoutesPaths.dashboard);
        }
      } else {
        if (mounted) {
          Toaster.error(title: 'Ошибка', description: 'Неверный пароль');
        }
      }
    } catch (e) {
      logError('Error unlocking store: $e', tag: 'LockStoreScreen');
      if (mounted) {
        Toaster.error(
          title: 'Ошибка',
          description: 'Произошла ошибка при разблокировке',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goHome() async {
    final syncState = ref.read(currentStoreSyncProvider);
    final isSyncStatusLoading = syncState.isLoading && syncState.value == null;
    final isApplyingRemoteUpdate =
        syncState.value?.isApplyingRemoteUpdate ?? false;
    final syncActivity =
        syncState.value?.syncActivity ?? StoreSyncActivity.idle;
    final isSyncInProgress =
        (syncState.value?.isSyncInProgress ?? false) ||
        syncActivity != StoreSyncActivity.idle;
    if (isSyncStatusLoading || isSyncInProgress || isApplyingRemoteUpdate) {
      return;
    }

    ref.read(mainStoreProvider.notifier).resetState();
    context.go(AppRoutesPaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final dbState = ref.watch(mainStoreProvider).value;
    final syncState = ref.watch(currentStoreSyncProvider);
    final syncStatus = syncState.value;
    final isSyncStatusLoading = syncState.isLoading && syncStatus == null;
    final isApplyingRemoteUpdate = syncStatus?.isApplyingRemoteUpdate ?? false;
    final syncActivity = syncStatus?.syncActivity ?? StoreSyncActivity.idle;
    final isSyncInProgress =
        (syncStatus?.isSyncInProgress ?? false) ||
        syncActivity != StoreSyncActivity.idle;
    final requiresUnlockToApply = syncStatus?.requiresUnlockToApply ?? false;
    final syncProgress = syncStatus?.syncProgress;
    final isUiBlocked =
        _isLoading ||
        isSyncStatusLoading ||
        isSyncInProgress ||
        isApplyingRemoteUpdate;
    final theme = Theme.of(context);
    final title = _titleForState(
      isSyncStatusLoading: isSyncStatusLoading,
      isApplyingRemoteUpdate: isApplyingRemoteUpdate,
      syncActivity: syncActivity,
      requiresUnlockToApply: requiresUnlockToApply,
    );
    final description = _descriptionForState(
      isSyncStatusLoading: isSyncStatusLoading,
      isApplyingRemoteUpdate: isApplyingRemoteUpdate,
      syncActivity: syncActivity,
      requiresUnlockToApply: requiresUnlockToApply,
    );
    final icon = _iconForState(
      isSyncStatusLoading: isSyncStatusLoading,
      isApplyingRemoteUpdate: isApplyingRemoteUpdate,
      syncActivity: syncActivity,
      requiresUnlockToApply: requiresUnlockToApply,
    );

    return PopScope(
      canPop:
          !isSyncStatusLoading && !isSyncInProgress && !isApplyingRemoteUpdate,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (dbState?.name != null)
                    Text(
                      dbState!.name!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (dbState?.path != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dbState!.path!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (syncProgress != null) ...[
                    const SizedBox(height: 24),
                    SnapshotSyncProgressCard(progress: syncProgress),
                  ] else if (requiresUnlockToApply) ...[
                    const SizedBox(height: 24),
                    const SnapshotSyncPendingApplyCard(),
                  ] else if (isSyncStatusLoading) ...[
                    const SizedBox(height: 24),
                    const _LockStoreSyncCheckingCard(),
                  ] else if (isApplyingRemoteUpdate) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 32),
                  if (!_hasSavedPassword)
                    TextField(
                      controller: _passwordController,
                      enabled: !isUiBlocked,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Пароль',
                        hintText: 'Введите пароль для разблокировки',
                        prefixIcon: const Icon(Icons.vpn_key),
                      ),
                      obscureText: true,
                      onSubmitted: isUiBlocked ? null : (_) => _unlock(),
                    ),
                  if (_hasSavedPassword)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.vpn_key,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Используется сохраненный пароль',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  SmoothButton(
                    label: 'Разблокировать',
                    onPressed: isUiBlocked ? null : _unlock,
                    loading: _isLoading,
                    type: SmoothButtonType.filled,
                    variant: SmoothButtonVariant.normal,
                    icon: const Icon(Icons.lock_open),
                  ),
                  const SizedBox(height: 16),
                  SmoothButton(
                    label: 'Закрыть и выйти',
                    onPressed: isUiBlocked ? null : _goHome,
                    type: SmoothButtonType.text,
                    variant: SmoothButtonVariant.normal,
                    icon: const Icon(Icons.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleForState({
    required bool isSyncStatusLoading,
    required bool isApplyingRemoteUpdate,
    required StoreSyncActivity syncActivity,
    required bool requiresUnlockToApply,
  }) {
    if (isSyncStatusLoading) {
      return 'Проверяем синхронизацию хранилища';
    }
    return switch (syncActivity) {
      StoreSyncActivity.preparingUpload =>
        'Подготавливаем отправку snapshot в облако',
      StoreSyncActivity.uploading => 'Отправляем snapshot в облако',
      StoreSyncActivity.preparingDownload =>
        'Подготавливаем загрузку snapshot из облака',
      StoreSyncActivity.downloading => 'Загружаем snapshot из облака',
      StoreSyncActivity.checkingStatus =>
        'Проверяем синхронизацию хранилища',
      StoreSyncActivity.idle => isApplyingRemoteUpdate
          ? 'Загружаем новую версию хранилища'
          : requiresUnlockToApply
          ? 'Новая версия уже применена'
          : 'В целях безопасности база данных заблокирована',
    };
  }

  String _descriptionForState({
    required bool isSyncStatusLoading,
    required bool isApplyingRemoteUpdate,
    required StoreSyncActivity syncActivity,
    required bool requiresUnlockToApply,
  }) {
    if (isSyncStatusLoading) {
      return 'Проверяем локальную и облачную snapshot-версии. Дождитесь завершения проверки перед разблокировкой.';
    }
    return switch (syncActivity) {
      StoreSyncActivity.preparingUpload =>
        'Готовим локальный snapshot к отправке. Разблокировка и выход будут доступны после завершения операции.',
      StoreSyncActivity.uploading =>
        'Передаём актуальную локальную версию в облако. Дождитесь завершения операции.',
      StoreSyncActivity.preparingDownload =>
        'Готовим загрузку удалённого snapshot. Разблокировка и выход будут доступны после завершения операции.',
      StoreSyncActivity.downloading =>
        'Загружаем удалённую snapshot-версию. Дождитесь завершения операции.',
      StoreSyncActivity.checkingStatus =>
        'Проверяем локальную и облачную snapshot-версии. Дождитесь завершения проверки.',
      StoreSyncActivity.idle => isApplyingRemoteUpdate
          ? 'Найдена новая версия в облаке. Дождитесь завершения загрузки и применения изменений. Пока процесс не завершится, разблокировка и выход недоступны.'
          : requiresUnlockToApply
          ? 'Удалённый snapshot уже записан локально. Разблокируйте хранилище, чтобы открыть обновлённые данные.'
          : 'Разблокируйте хранилище, чтобы продолжить работу.',
    };
  }

  IconData _iconForState({
    required bool isSyncStatusLoading,
    required bool isApplyingRemoteUpdate,
    required StoreSyncActivity syncActivity,
    required bool requiresUnlockToApply,
  }) {
    if (isSyncStatusLoading) {
      return Icons.cloud_sync_outlined;
    }
    return switch (syncActivity) {
      StoreSyncActivity.preparingUpload ||
      StoreSyncActivity.uploading => Icons.cloud_upload_outlined,
      StoreSyncActivity.preparingDownload ||
      StoreSyncActivity.downloading => Icons.cloud_download_outlined,
      StoreSyncActivity.checkingStatus => Icons.cloud_sync_outlined,
      StoreSyncActivity.idle => isApplyingRemoteUpdate
          ? Icons.cloud_download_outlined
          : requiresUnlockToApply
          ? Icons.cloud_done_outlined
          : Icons.lock_outline,
    };
  }
}

class _LockStoreSyncCheckingCard extends StatelessWidget {
  const _LockStoreSyncCheckingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Проверяем, нужно ли применить новую версию из облака...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
