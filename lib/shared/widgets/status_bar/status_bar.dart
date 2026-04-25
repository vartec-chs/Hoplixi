import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/db_core/old/provider/main_store_provider.dart';
import 'package:hoplixi/shared/widgets/update_marker.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/auto_lock_provider.dart';

part 'status_bar_components.dart';
part 'status_bar_state.dart';

const statusBarHeight = 28.0;

/// Простой статус-бар для отображения информации внизу экрана
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(statusBarStateProvider);

    if (statusState.hidden) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: statusBarHeight,
      decoration: BoxDecoration(
        color:
            statusState.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Левая часть - основной текст/статус
            Expanded(
              child: Row(
                children: [
                  if (statusState.loading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  if (statusState.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: statusState.icon!,
                    ),
                  Flexible(
                    child: Text(
                      statusState.message,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            statusState.textColor ??
                            Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const _CurrentRouteWidget(),
                ],
              ),
            ),
            // Правая часть - информация о БД и дополнительный контент
            const Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                _AutoLockTimerWidget(),
                _UpdateMarkerWidget(),
                _CloudSyncStatusWidget(),
                _DatabaseStatusWidget(),
                _BuildModeWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
