import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/snapshot_sync_progress_card.dart';
import 'package:hoplixi/shared/ui/button.dart';

class CloseStoreSyncScreen extends ConsumerStatefulWidget {
  const CloseStoreSyncScreen({super.key});

  @override
  ConsumerState<CloseStoreSyncScreen> createState() =>
      _CloseStoreSyncScreenState();
}

class _CloseStoreSyncScreenState extends ConsumerState<CloseStoreSyncScreen> {
  bool _isResolvingDecision = false;

  bool _shouldAskAboutUpload(StoreSyncStatus? status) {
    return status != null &&
        (status.compareResult == StoreVersionCompareResult.localNewer ||
            status.compareResult == StoreVersionCompareResult.remoteMissing) &&
        !status.isSyncInProgress &&
        status.syncProgress == null &&
        !status.requiresUnlockToApply;
  }

  String _uploadDecisionDescription(StoreSyncStatus? status) {
    return switch (status?.compareResult) {
      StoreVersionCompareResult.remoteMissing =>
        'Cloud sync уже подключён, но облачная snapshot-версия для этого хранилища ещё не создана. Перед закрытием выберите, нужно ли сначала отправить текущую локальную версию в облако.',
      StoreVersionCompareResult.localNewer =>
        'Локальная snapshot-версия новее облачной. Перед закрытием выберите, нужно ли отправить обновлённую версию в облако.',
      _ =>
        'Идёт синхронизация изменений перед закрытием. Это окно закроется автоматически.',
    };
  }

  String _uploadDecisionCardTitle(StoreSyncStatus? status) {
    return switch (status?.compareResult) {
      StoreVersionCompareResult.remoteMissing =>
        'Создать первую облачную версию?',
      StoreVersionCompareResult.localNewer =>
        'Отправить новую облачную версию?',
      _ => 'Отправить изменения в облако?',
    };
  }

  String _uploadDecisionCardText(StoreSyncStatus? status) {
    return switch (status?.compareResult) {
      StoreVersionCompareResult.remoteMissing =>
        'Если пропустить отправку, синхронизация останется подключённой, но в облаке пока не будет snapshot этого хранилища. Авто-отправку можно включить в разделе "Настройки -> Синхронизация".',
      StoreVersionCompareResult.localNewer =>
        'Если пропустить отправку, хранилище закроется сразу, а облачная версия останется старой. Авто-отправку можно включить в разделе "Настройки -> Синхронизация".',
      _ =>
        'Если пропустить отправку, хранилище закроется сразу без обновления облачной версии. Авто-отправку можно включить в разделе "Настройки -> Синхронизация".',
    };
  }

  Future<void> _resolveUploadDecision(bool shouldUpload) async {
    if (_isResolvingDecision) {
      return;
    }

    setState(() {
      _isResolvingDecision = true;
    });
    ref
        .read(mainStoreProvider.notifier)
        .resolveCloseStoreUploadDecision(shouldUpload);
  }

  @override
  Widget build(BuildContext context) {
    final dbState = ref.watch(mainStoreProvider).value;
    final syncStatus =
        ref.watch(closeStoreSyncStatusProvider) ??
        ref.watch(currentStoreSyncProvider).value;
    final syncProgress = syncStatus?.syncProgress;
    final requiresUnlockToApply = syncStatus?.requiresUnlockToApply ?? false;
    final shouldAskAboutUpload = _shouldAskAboutUpload(syncStatus);
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
                    shouldAskAboutUpload
                        ? _uploadDecisionDescription(syncStatus)
                        : requiresUnlockToApply
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
                  if (shouldAskAboutUpload)
                    _CloseStoreUploadDecisionCard(
                      title: _uploadDecisionCardTitle(syncStatus),
                      description: _uploadDecisionCardText(syncStatus),
                      isLoading: _isResolvingDecision,
                      onUploadAndClose: () => _resolveUploadDecision(true),
                      onCloseWithoutUpload: () => _resolveUploadDecision(false),
                    )
                  else if (syncProgress != null)
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

class _CloseStoreUploadDecisionCard extends StatelessWidget {
  const _CloseStoreUploadDecisionCard({
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onUploadAndClose,
    required this.onCloseWithoutUpload,
  });

  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onUploadAndClose;
  final VoidCallback onCloseWithoutUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SmoothButton(
              label: 'Отправить и закрыть',
              loading: isLoading,
              onPressed: isLoading ? null : onUploadAndClose,
            ),
            const SizedBox(height: 10),
            SmoothButton(
              label: 'Закрыть без отправки',
              type: SmoothButtonType.outlined,
              onPressed: isLoading ? null : onCloseWithoutUpload,
            ),
          ],
        ),
      ),
    );
  }
}
