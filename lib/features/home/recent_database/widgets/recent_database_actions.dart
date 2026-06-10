import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/home/recent_database/controllers/recent_database_cloud_sync_controller.dart';
import 'package:hoplixi/features/home/recent_database/controllers/recent_database_open_controller.dart';
import 'package:hoplixi/features/home/recent_database/models/recent_database_card_view_state.dart';
import 'package:hoplixi/features/home/recent_database/widgets/cloud_sync_progress_panel.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cloud_lock_status_banner.dart';

class RecentDatabaseActions extends ConsumerWidget {
  const RecentDatabaseActions({
    super.key,
    required this.entry,
    required this.viewState,
  });

  final DatabaseEntry entry;
  final RecentDatabaseCardViewState viewState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (viewState.isCloudLockChecking) {
      return const CloudLockStatusBanner(
        icon: LucideIcons.cloudCog,
        title: 'Проверяем cloud lock',
        message:
            'Кнопки появятся после проверки, что хранилище не открыто на другом устройстве.',
        showProgress: true,
      );
    }

    if (viewState.isCloudLockReleasing) {
      return const CloudLockStatusBanner(
        icon: LucideIcons.cloudOff,
        title: 'Закрываем cloud-сессию',
        message:
            'Удаляем lock-файл в облаке. Действия с хранилищем временно недоступны.',
        showProgress: true,
      );
    }

    final cloudSyncState = ref.watch(recentDatabaseCloudSyncControllerProvider);
    final cloudSyncProgress = cloudSyncState.progress;
    final isCheckingCloudVersion = cloudSyncState.isChecking;
    final syncProvider = viewState.syncProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (syncProvider != null) ...[
          SmoothButton(
            label: cloudSyncProgress == null
                ? 'Проверить и установить новую версию'
                : _buildProgressButtonLabel(cloudSyncProgress),
            type: SmoothButtonType.outlined,
            isFullWidth: true,
            icon: CloudSyncProviderLogo(
              metadata: syncProvider.metadata,
              size: 20,
            ),
            loading: isCheckingCloudVersion,
            onPressed: (viewState.isOpening || isCheckingCloudVersion)
                ? null
                : () => ref
                      .read(recentDatabaseCloudSyncControllerProvider.notifier)
                      .checkAndInstallLatestVersion(entry),
          ),
          const SizedBox(height: 12),
        ],
        if (isCheckingCloudVersion)
          CloudSyncProgressPanel(progress: cloudSyncProgress)
        else
          SmoothButton(
            label: viewState.isOpening ? 'Открытие...' : 'Открыть',

            isFullWidth: true,
            icon: const Icon(LucideIcons.folderOpen),
            loading: viewState.isOpening,
            onPressed: viewState.isOpening
                ? null
                : () => ref
                      .read(recentDatabaseOpenControllerProvider)
                      .open(context, entry, widgetRef: ref),
          ),
      ],
    );
  }

  String _buildProgressButtonLabel(SnapshotSyncProgress progress) {
    return '${progress.title} · шаг ${progress.stepIndex}/${progress.totalSteps}';
  }
}
