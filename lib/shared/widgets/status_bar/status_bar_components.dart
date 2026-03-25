part of 'status_bar.dart';

class _AutoLockTimerWidget extends ConsumerStatefulWidget {
  const _AutoLockTimerWidget();

  @override
  ConsumerState<_AutoLockTimerWidget> createState() =>
      _AutoLockTimerWidgetState();
}

class _AutoLockTimerWidgetState extends ConsumerState<_AutoLockTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autoLockState = ref.watch(autoLockProvider);

    if (!autoLockState.isWarning) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                'Автоблокировка: ${autoLockState.remainingSeconds}с',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для отображения состояния базы данных
class _DatabaseStatusWidget extends ConsumerWidget {
  const _DatabaseStatusWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(mainStoreProvider);

    return dbState.when(
      data: (state) {
        if (state.isIdle || state.isClosed) {
          return _buildStatusChip(
            context,
            icon: Icons.storage_outlined,
            label: 'БД не открыта',
            color: Colors.grey,
          );
        }

        if (state.isLoading) {
          return _buildStatusChip(
            context,
            icon: Icons.hourglass_empty,
            label: 'Загрузка...',
            color: Colors.blue,
          );
        }

        if (state.isLocked) {
          return _buildStatusChip(
            context,
            icon: Icons.lock,
            label: state.name ?? 'Заблокировано',
            color: Colors.orange,
            tooltip: state.path,
          );
        }

        if (state.isOpen) {
          return _buildStatusChip(
            context,
            icon: Icons.check_circle,
            label: state.name ?? 'Открыта',
            color: Colors.green,
            tooltip: state.path,
          );
        }

        if (state.hasError) {
          return _buildStatusChip(
            context,
            icon: Icons.error,
            label: 'Ошибка БД',
            color: Colors.red,
            tooltip: state.error?.message,
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => _buildStatusChip(
        context,
        icon: Icons.hourglass_empty,
        label: 'Загрузка...',
        color: Colors.blue,
      ),
      error: (error, stack) => _buildStatusChip(
        context,
        icon: Icons.error,
        label: 'Ошибка',
        color: Colors.red,
        tooltip: error.toString(),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    String? tooltip,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: chip);
    }

    return chip;
  }
}

/// Виджет для отображения маркера обновлений
class _UpdateMarkerWidget extends ConsumerWidget {
  const _UpdateMarkerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(dataUpdateStreamProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: UpdateMarker(updateStream: stream),
    );
  }
}

/// Виджет для отображения состояния cloud sync
class _CloudSyncStatusWidget extends ConsumerWidget {
  const _CloudSyncStatusWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(currentStoreSyncProvider);

    return syncState.when(
      loading: () => _buildSyncChip(
        icon: Icons.sync,
        label: 'Синх: ...',
        color: Colors.blue,
        tooltip: 'Обновление статуса cloud sync',
        spinning: true,
      ),
      error: (error, _) => _buildSyncChip(
        icon: Icons.cloud_off,
        label: 'Синх: ошибка',
        color: Colors.red,
        tooltip: error.toString(),
      ),
      data: (status) {
        if (!status.isStoreOpen && status.binding == null) {
          return const SizedBox.shrink();
        }

        if (status.binding == null) {
          return _buildSyncChip(
            icon: Icons.cloud_off,
            label: 'Синх: нет',
            color: Colors.grey,
            tooltip: 'Cloud sync для текущего хранилища не подключен',
          );
        }

        if (status.requiresUnlockToApply) {
          return _buildSyncChip(
            icon: Icons.lock,
            label: 'Синх: разблок.',
            color: Colors.orange,
            tooltip:
                'Удалённая snapshot-версия уже загружена. Разблокируйте хранилище, чтобы применить изменения.',
          );
        }

        if (status.pendingConflict != null ||
            status.compareResult == StoreVersionCompareResult.conflict) {
          return _buildSyncChip(
            icon: Icons.warning,
            label: 'Синх: конфликт',
            color: Colors.red,
            tooltip: 'Обнаружен конфликт snapshot-версий',
          );
        }

        return switch (status.compareResult) {
          StoreVersionCompareResult.remoteNewer => _buildSyncChip(
            icon: Icons.cloud_download,
            label: 'Синх: remote',
            color: Colors.orange,
            tooltip: 'Удалённая snapshot-версия новее локальной',
          ),
          StoreVersionCompareResult.localNewer => _buildSyncChip(
            icon: Icons.cloud_upload,
            label: 'Синх: local',
            color: Colors.blue,
            tooltip: 'Локальная snapshot-версия новее удалённой',
          ),
          StoreVersionCompareResult.same => _buildSyncChip(
            icon: Icons.cloud_done,
            label: 'Синх: OK',
            color: Colors.green,
            tooltip: 'Локальная и удалённая snapshot-версии совпадают',
          ),
          StoreVersionCompareResult.remoteMissing => _buildSyncChip(
            icon: Icons.cloud_queue,
            label: 'Синх: нет облака',
            color: Colors.grey,
            tooltip: 'Удалённая snapshot-версия ещё не создана',
          ),
          StoreVersionCompareResult.differentStore => _buildSyncChip(
            icon: Icons.cloud_off,
            label: 'Синх: store',
            color: Colors.red,
            tooltip: 'Удалённая snapshot-версия относится к другому хранилищу',
          ),
          StoreVersionCompareResult.conflict => _buildSyncChip(
            icon: Icons.warning,
            label: 'Синх: конфликт',
            color: Colors.red,
            tooltip: 'Обнаружен конфликт snapshot-версий',
          ),
        };
      },
    );
  }

  Widget _buildSyncChip({
    required IconData icon,
    required String label,
    required Color color,
    String? tooltip,
    bool spinning = false,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinning
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: color,
                  ),
                )
              : Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: content);
    }

    return content;
  }
}

/// Виджет для отображения режима сборки (только в debug)
class _BuildModeWidget extends StatelessWidget {
  const _BuildModeWidget();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bug_report, size: 12, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            'Debug',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения текущего пути маршрута (только в debug)
class _CurrentRouteWidget extends StatelessWidget {
  const _CurrentRouteWidget();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final routePath = GoRouterState.of(context).uri.path;
    if (routePath.isEmpty || routePath == '/') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route, size: 12, color: Colors.purple),
            const SizedBox(width: 4),
            Text(
              routePath,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
