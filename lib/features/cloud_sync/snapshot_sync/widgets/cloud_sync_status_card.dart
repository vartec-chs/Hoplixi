import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';

class CloudSyncStatusCard extends StatelessWidget {
  const CloudSyncStatusCard({
    required this.status,
    required this.token,
    super.key,
  });

  final StoreSyncStatus status;
  final AuthTokenEntry? token;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localManifest = status.localManifest;
    final remoteManifest = status.remoteManifest;
    final compareState = _resolveCompareState(status, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: compareState.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: compareState.borderColor),
          ),
          child: Row(
            children: [
              Icon(compareState.icon, color: compareState.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  compareState.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusInfoChip(
              icon: Icons.inventory_2_outlined,
              label: 'Хранилище',
              value: status.storeName ?? '—',
            ),
            _StatusInfoChip(
              icon: Icons.cloud_outlined,
              label: 'Провайдер',
              value: status.binding?.provider.metadata.displayName ?? '—',
            ),
            _StatusInfoChip(
              icon: Icons.account_circle_outlined,
              label: 'Аккаунт',
              value: token?.displayLabel ?? '—',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusMetricCard(
              title: 'Локальная ревизия',
              value: _formatRevision(localManifest?.revision),
            ),
            _StatusMetricCard(
              title: 'Удалённая ревизия',
              value: _formatRevision(remoteManifest?.revision),
            ),
            _StatusMetricCard(
              title: 'Последняя синхронизация',
              value: _formatSyncTime(localManifest?.sync?.syncedAt),
            ),
          ],
        ),
        if (status.remoteCheckSkippedOffline) ...[
          const SizedBox(height: 12),
          const _InlineHint(
            icon: Icons.wifi_off_rounded,
            text:
                'Нет доступа к интернету. Автоматическая проверка удалённой версии пропущена.',
          ),
        ],
        if (status.requiresUnlockToApply) ...[
          const SizedBox(height: 8),
          const _InlineHint(
            icon: Icons.lock_open_rounded,
            text:
                'Удалённый snapshot уже записан локально. Разблокируйте хранилище, чтобы применить изменения.',
          ),
        ],
      ],
    );
  }

  _CompareState _resolveCompareState(
    StoreSyncStatus status,
    ColorScheme colorScheme,
  ) {
    if (status.remoteCheckSkippedOffline) {
      return _CompareState(
        label: 'Проверка недоступна: нет интернета',
        icon: Icons.wifi_off_rounded,
        iconColor: colorScheme.onSecondaryContainer,
        borderColor: colorScheme.secondary,
        backgroundColor: colorScheme.secondaryContainer,
      );
    }

    return switch (status.compareResult) {
      StoreVersionCompareResult.differentStore => _CompareState(
        label: 'Несоответствие идентификаторов хранилища',
        icon: Icons.report_problem_rounded,
        iconColor: colorScheme.onErrorContainer,
        borderColor: colorScheme.error,
        backgroundColor: colorScheme.errorContainer,
      ),
      StoreVersionCompareResult.same => _CompareState(
        label: 'Локальная и удалённая версии совпадают',
        icon: Icons.task_alt_rounded,
        iconColor: colorScheme.onPrimaryContainer,
        borderColor: colorScheme.primary,
        backgroundColor: colorScheme.primaryContainer,
      ),
      StoreVersionCompareResult.localNewer => _CompareState(
        label: 'Локальная версия новее облачной',
        icon: Icons.upload_rounded,
        iconColor: colorScheme.onTertiaryContainer,
        borderColor: colorScheme.tertiary,
        backgroundColor: colorScheme.tertiaryContainer,
      ),
      StoreVersionCompareResult.remoteNewer => _CompareState(
        label: 'Удалённая версия новее локальной',
        icon: Icons.download_rounded,
        iconColor: colorScheme.onSecondaryContainer,
        borderColor: colorScheme.secondary,
        backgroundColor: colorScheme.secondaryContainer,
      ),
      StoreVersionCompareResult.conflict => _CompareState(
        label: 'Обнаружен конфликт версий',
        icon: Icons.sync_problem_rounded,
        iconColor: colorScheme.onErrorContainer,
        borderColor: colorScheme.error,
        backgroundColor: colorScheme.errorContainer,
      ),
      StoreVersionCompareResult.remoteMissing => _CompareState(
        label:
            'Удалённой версии пока нет. Вы можете загрузить её в облако в секции выше.',
        icon: Icons.cloud_upload_rounded,
        iconColor: colorScheme.onSurfaceVariant,
        borderColor: colorScheme.outline,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
    };
  }

  String _formatSyncTime(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }

  String _formatRevision(Object? value) {
    if (value == null) {
      return '—';
    }
    return value.toString();
  }
}

class _StatusInfoChip extends StatelessWidget {
  const _StatusInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusMetricCard extends StatelessWidget {
  const _StatusMetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _CompareState {
  const _CompareState({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
}
