import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/old/provider/main_store_backup_orchestrator_provider.dart';
import 'package:hoplixi/main_db/old/provider/main_store_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/providers/drawer_category_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/providers/drawer_tag_filter_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/widgets/category_section.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/widgets/tag_section.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/widgets/close_database_button.dart';
import 'package:typed_prefs/typed_prefs.dart';

/// Drawer с фильтрацией по категориям и тегам (для мобильных устройств)
class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key, required this.entityType});

  final EntityType entityType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(child: DashboardDrawerContent(entityType: entityType)),
    );
  }
}

/// Контент панели фильтрации (может использоваться как в Drawer, так и как постоянная панель)
class DashboardDrawerContent extends ConsumerStatefulWidget {
  const DashboardDrawerContent({super.key, required this.entityType});

  final EntityType entityType;

  @override
  ConsumerState<DashboardDrawerContent> createState() =>
      _DashboardDrawerContentState();
}

class _DashboardDrawerContentState
    extends ConsumerState<DashboardDrawerContent> {
  BackupScope _parseBackupScope(String? raw) {
    switch (raw) {
      case 'databaseOnly':
        return BackupScope.databaseOnly;
      case 'encryptedFilesOnly':
        return BackupScope.encryptedFilesOnly;
      case 'full':
      default:
        return BackupScope.full;
    }
  }

  Future<void> _createBackupNow() async {
    final store = getIt<PreferencesService>().settingsPrefs;
    final backupPath = await store.getBackupPath();
    final scopeRaw = await store.getBackupScope();
    final backupMaxPerStore = await store.getBackupMaxPerStore();
    final scope = _parseBackupScope(scopeRaw);

    final result = await ref
        .read(mainStoreBackupOrchestratorProvider)
        .createBackup(
          scope: scope,
          outputDirPath: backupPath,
          periodic: false,
          maxBackupsPerStore: backupMaxPerStore,
        );

    if (!mounted) return;

    if (result == null) {
      Toaster.error(
        title: 'Бэкап не создан',
        description: 'Проверьте, что хранилище открыто',
      );
      return;
    }

    Toaster.success(title: 'Бэкап создан', description: result.backupPath);
  }

  @override
  void didUpdateWidget(DashboardDrawerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если entityType изменился, сбрасываем выбранные фильтры для старого типа
    if (oldWidget.entityType != widget.entityType) {
      ref
          .read(drawerCategoryFilterProvider(oldWidget.entityType).notifier)
          .clearSelection();
      ref
          .read(drawerTagFilterProvider(oldWidget.entityType).notifier)
          .clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Column(
        key: ValueKey(widget.entityType),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок
          SizedBox(
            height: 50,
            child: _DrawerHeader(entityType: widget.entityType, theme: theme),
          ),
          const Divider(height: 1),

          // Контент: секции 50/50
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6,
                    ),
                    child: CategorySection(entityType: widget.entityType),
                  ),
                ),

                const SizedBox(height: 8.0),
                const Divider(height: 1),
                const SizedBox(height: 4.0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 2,
                    ),
                    child: TagSection(entityType: widget.entityType),
                  ),
                ),
              ],
            ),
          ),
          if (isMobile) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _DrawerMobileActions(onCreateBackupNow: _createBackupNow),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawerHeader extends ConsumerWidget {
  const _DrawerHeader({required this.entityType, required this.theme});

  final EntityType entityType;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCategorySelections = ref.watch(
      drawerCategoryFilterProvider(entityType).select(
        (s) => s.whenOrNull(data: (s) => s.selectedIds.isNotEmpty) ?? false,
      ),
    );
    final hasTagSelections = ref.watch(
      drawerTagFilterProvider(entityType).select(
        (s) => s.whenOrNull(data: (s) => s.selectedIds.isNotEmpty) ?? false,
      ),
    );
    final hasAnySelections = hasCategorySelections || hasTagSelections;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Фильтры',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (hasAnySelections)
            SmoothButton(
              onPressed: () {
                ref
                    .read(drawerCategoryFilterProvider(entityType).notifier)
                    .clearSelection();
                ref
                    .read(drawerTagFilterProvider(entityType).notifier)
                    .clearSelection();
              },
              label: 'Очистить все',
              size: SmoothButtonSize.small,
              type: SmoothButtonType.text,
            ),
        ],
      ),
    );
  }
}

class _DrawerMobileActions extends ConsumerWidget {
  const _DrawerMobileActions({required this.onCreateBackupNow});

  final Future<void> Function() onCreateBackupNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStoreOpen = ref
        .watch(mainStoreProvider)
        .maybeWhen(data: (state) => state.isOpen, orElse: () => false);

    return Row(
      children: [
        const Expanded(
          child: CloseDatabaseButton(type: CloseDatabaseButtonType.smooth),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SmoothButton(
            label: 'Бэкап',
            size: SmoothButtonSize.small,
            icon: const Icon(Icons.backup),
            onPressed: isStoreOpen ? onCreateBackupNow : null,
            type: SmoothButtonType.filled,
          ),
        ),
      ],
    );
  }
}
