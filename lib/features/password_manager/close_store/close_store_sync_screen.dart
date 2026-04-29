import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/close_sync_state.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/close_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/snapshot_sync_progress_card.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

class CloseStoreSyncScreen extends ConsumerStatefulWidget {
  const CloseStoreSyncScreen({super.key});

  @override
  ConsumerState<CloseStoreSyncScreen> createState() =>
      _CloseStoreSyncScreenState();
}

class _CloseStoreSyncScreenState extends ConsumerState<CloseStoreSyncScreen> {
  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Scaffold(body: Center(child: CloseStoreSyncContent())),
    );
  }
}

class CloseStoreSyncDialogHost extends ConsumerWidget {
  const CloseStoreSyncDialogHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closeSyncState = ref.watch(mainStoreCloseSyncProvider).value;
    final isVisible =
        closeSyncState?.isActive == true ||
        ref.watch(closeStoreSyncStatusProvider) != null;

    return PopScope(
      canPop: !isVisible,
      child: Stack(
        children: [
          child,
          if (isVisible) const Positioned.fill(child: _CloseStoreSyncDialog()),
        ],
      ),
    );
  }
}

class _CloseStoreSyncDialog extends StatelessWidget {
  const _CloseStoreSyncDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: theme.colorScheme.scrim.withValues(alpha: 0.54),
        ),
        Positioned.fill(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      maxHeight: constraints.maxHeight > 32
                          ? constraints.maxHeight - 32
                          : constraints.maxHeight,
                    ),
                    child: const Dialog(
                      clipBehavior: Clip.antiAlias,
                      child: CloseStoreSyncContent(padding: EdgeInsets.all(16)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CloseStoreSyncContent extends ConsumerStatefulWidget {
  const CloseStoreSyncContent({
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<CloseStoreSyncContent> createState() =>
      _CloseStoreSyncContentState();
}

class _CloseStoreSyncContentState extends ConsumerState<CloseStoreSyncContent>
    with SingleTickerProviderStateMixin {
  bool _isResolvingDecision = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        'Хранилище уже закрыто, и теперь можно завершить синхронизацию. Облачная snapshot-версия для этого хранилища ещё не создана. Перед завершением выберите, нужно ли сначала отправить текущую локальную версию в облако.',
      StoreVersionCompareResult.localNewer =>
        'Хранилище уже закрыто, и локальная snapshot-версия новее облачной. Перед завершением выберите, нужно ли отправить обновлённую версию в облако.',
      _ =>
        'Хранилище уже закрыто, идёт финальная синхронизация изменений. Это окно закроется автоматически после завершения.',
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
        'Если пропустить отправку, это хранилище останется без облачной snapshot-версии. При дальнейшем использовании на разных устройствах могут появиться неразрешимые конфликты. Авто-отправку можно включить в разделе "Настройки -> Синхронизация".',
      StoreVersionCompareResult.localNewer =>
        'Если пропустить отправку, облачная версия останется старой. При дальнейшем использовании на разных устройствах могут появиться неразрешимые конфликты. Авто-отправку можно включить в разделе "Настройки -> Синхронизация".',
      _ =>
        'Если пропустить отправку, облако не получит актуальную версию этого хранилища. При дальнейшем использовании на разных устройствах могут появиться неразрешимые конфликты. Авто-отправку можно включить в разделе "Настройки -> Синхронизация".',
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
    final closeSyncState = ref.watch(mainStoreCloseSyncProvider).value;
    final closeSyncStatus = closeSyncState?.status;
    final isChecking =
        closeSyncState?.phase == MainStoreCloseSyncPhase.checking;
    final syncStatus = isChecking
        ? null
        : closeSyncStatus ??
              ref.watch(closeStoreSyncStatusProvider) ??
              ref.watch(currentStoreSyncSnapshotProvider) ??
              ref.watch(currentStoreSyncProvider).value;
    final syncProgress = syncStatus?.syncProgress;
    final requiresUnlockToApply = syncStatus?.requiresUnlockToApply ?? false;
    final shouldAskAboutUpload = _shouldAskAboutUpload(syncStatus);
    final theme = Theme.of(context);
    final title = isChecking
        ? 'Проверка синхронизации'
        : 'Синхронизация после закрытия хранилища';
    final description = isChecking
        ? 'Проверяем локальную и облачную snapshot-версии после закрытия хранилища. Не закрывайте приложение до завершения проверки.'
        : shouldAskAboutUpload
        ? _uploadDecisionDescription(syncStatus)
        : requiresUnlockToApply
        ? 'Удалённый snapshot уже применён локально после закрытия хранилища. Экран закроется автоматически после завершения сценария закрытия.'
        : 'Идёт финальная синхронизация изменений после закрытия хранилища. Это окно закроется автоматически.';
    final body = isChecking
        ? const _CloseStoreCheckingCard(key: ValueKey('checking'))
        : shouldAskAboutUpload
        ? _CloseStoreUploadDecisionCard(
            key: const ValueKey('upload-decision'),
            title: _uploadDecisionCardTitle(syncStatus),
            description: _uploadDecisionCardText(syncStatus),
            isLoading: _isResolvingDecision,
            onUploadAndClose: () => _resolveUploadDecision(true),
            onCloseWithoutUpload: () => _resolveUploadDecision(false),
          )
        : syncProgress != null
        ? SnapshotSyncProgressCard(
            key: const ValueKey('sync-progress'),
            progress: syncProgress,
          )
        : requiresUnlockToApply
        ? const SnapshotSyncPendingApplyCard(key: ValueKey('pending-apply'))
        : const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          padding: widget.padding,
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  reverseDuration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseStoreCheckingCard extends StatelessWidget {
  const _CloseStoreCheckingCard({super.key});

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
                'Определяем, нужно ли отправить изменения в облако...',
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

class _CloseStoreUploadDecisionCard extends StatelessWidget {
  const _CloseStoreUploadDecisionCard({
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onUploadAndClose,
    required this.onCloseWithoutUpload,
    super.key,
  });

  final String title;
  final String description;
  final bool isLoading;
  final VoidCallback onUploadAndClose;
  final VoidCallback onCloseWithoutUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: super.key,
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
              label: 'Отправить и завершить',
              loading: isLoading,
              onPressed: isLoading ? null : onUploadAndClose,
            ),
            const SizedBox(height: 10),
            SmoothButton(
              label: 'Завершить без отправки',
              type: SmoothButtonType.outlined,
              onPressed: isLoading ? null : onCloseWithoutUpload,
            ),
          ],
        ),
      ),
    );
  }
}
