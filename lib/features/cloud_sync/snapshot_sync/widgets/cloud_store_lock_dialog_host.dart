import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_cloud_lock_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

class CloudStoreLockDialogHost extends ConsumerWidget {
  const CloudStoreLockDialogHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(currentStoreCloudLockProvider);
    final storeState = ref.watch(mainStoreProvider).value;
    final isStoreOpen = storeState?.isOpen ?? false;
    final visible = isStoreOpen && _shouldShow(lockState);

    return PopScope(
      canPop: !visible,
      child: Stack(
        children: [
          child,
          if (visible)
            Positioned.fill(child: _CloudStoreLockDialog(lockState: lockState)),
        ],
      ),
    );
  }

  bool _shouldShow(AsyncValue<CloudStoreLockState> lockState) {
    if (lockState.isLoading && lockState.value == null) {
      return true;
    }
    return lockState.value?.shouldBlockUi == true || lockState.hasError;
  }
}

class _CloudStoreLockDialog extends ConsumerWidget {
  const _CloudStoreLockDialog({required this.lockState});

  final AsyncValue<CloudStoreLockState> lockState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = lockState.value;
    final phase = state?.phase;

    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: theme.colorScheme.scrim.withValues(alpha: 0.48),
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Dialog(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: switch (phase) {
                  CloudStoreLockPhase.lockedByAnotherDevice =>
                    _LockedByAnotherDeviceContent(state: state!),
                  CloudStoreLockPhase.error => _LockErrorContent(state: state!),
                  CloudStoreLockPhase.releasing =>
                    const _CheckingLockContent(
                      title: 'Закрываем Cloud Lock',
                      message:
                          'Удаляем lock-файл в облаке. Действия с хранилищем временно недоступны.',
                    ),
                  _ => const _CheckingLockContent(),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckingLockContent extends StatelessWidget {
  const _CheckingLockContent({
    this.title = 'Проверка Cloud Lock',
    this.message =
        'Хранилище откроется после проверки, что оно не открыто на другом устройстве. Это помогает избежать конфликтов при синхронизации. Пожалуйста, подождите.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _LockedByAnotherDeviceContent extends ConsumerWidget {
  const _LockedByAnotherDeviceContent({required this.state});

  final CloudStoreLockState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lock = state.conflictingLock;
    final deviceName = lock?.deviceName.trim().isNotEmpty == true
        ? lock!.deviceName
        : 'другом устройстве';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Хранилище уже открыто',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Cloud lock показывает, что это хранилище сейчас открыто на $deviceName. '
          'Параллельная работа может привести к конфликту snapshot-файлов.',
          style: theme.textTheme.bodyMedium,
        ),
        if (lock != null) ...[
          const SizedBox(height: 16),
          _LockDetail(label: 'Устройство', value: lock.deviceName),
          _LockDetail(label: 'Платформа', value: lock.platform),
          _LockDetail(
            label: 'Обновлён',
            value: _formatLockTime(lock.updatedAt),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                ref
                    .read(currentStoreCloudLockProvider.notifier)
                    .acceptRiskForCurrentStore();
              },
              child: const Text('Открыть на свой риск'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                ref
                    .read(mainStoreManagerStateProvider.notifier)
                    .lockStore(skipSnapshotSync: true);
              },
              child: const Text('Выйти'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockErrorContent extends ConsumerWidget {
  const _LockErrorContent({required this.state});

  final CloudStoreLockState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cloud Lock недоступен',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Не удалось проверить, открыто ли хранилище на другом устройстве.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SmoothButton(
              onPressed: () {
                ref.read(currentStoreCloudLockProvider.notifier).retry();
              },
              label: 'Повторить',
            ),
            const SizedBox(width: 8),
            SmoothButton.text(
              onPressed: () {
                ref
                    .read(mainStoreManagerStateProvider.notifier)
                    .lockStore(skipSnapshotSync: true);
              },
              label: 'Выйти',
              variant: SmoothButtonVariant.error,
            ),
          ],
        ),
      ],
    );
  }
}

class _LockDetail extends StatelessWidget {
  const _LockDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

String _formatLockTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return parsed.toLocal().toString();
}
