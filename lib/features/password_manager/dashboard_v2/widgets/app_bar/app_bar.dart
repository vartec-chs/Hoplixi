import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/store_settings/index.dart';
import 'package:hoplixi/main_db/core/models/filter/index.dart';
import 'package:hoplixi/main_db/providers/main_store_backup_orchestrator_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:typed_prefs/typed_prefs.dart';

import '../../models/dashboard_entity_type.dart';
import '../../models/dashboard_filter_state.dart';
import '../../models/dashboard_filter_tab.dart';
import '../../providers/dashboard_filter_provider.dart';
import '../../providers/filter_providers/filter_providers.dart';
import '../filters_modal/filters_modal.dart';
import 'entity_type_compact_dropdown.dart';
import 'filter_tabs.dart';

enum _DashboardMenuAction {
  storeSettings,
  pinnedEntityTypes,
  backupNow,
  keepassImport,
}

final class DashboardV2SliverAppBar extends ConsumerStatefulWidget {
  const DashboardV2SliverAppBar({
    required this.entityType,
    required this.onEntityTypeChanged,
    super.key,
    this.onMenuPressed,
    this.expandedHeight = 176.0,
    this.collapsedHeight = 60.0,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.showEntityTypeSelector = true,
    this.additionalActions,
    this.onFilterPressed,
    this.onFilterApplied,
    this.isScrolled = false,
  });

  final VoidCallback? onMenuPressed;
  final DashboardEntityType entityType;
  final ValueChanged<DashboardEntityType> onEntityTypeChanged;
  final double expandedHeight;
  final double collapsedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool isScrolled;
  final bool showEntityTypeSelector;
  final List<Widget>? additionalActions;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onFilterApplied;

  @override
  ConsumerState<DashboardV2SliverAppBar> createState() =>
      _DashboardV2SliverAppBarState();
}

final class _DashboardV2SliverAppBarState
    extends ConsumerState<DashboardV2SliverAppBar> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(dashboardFilterProvider).query,
    );
    _searchFocusNode = FocusNode();
    logDebug('DashboardV2SliverAppBar: Инициализация');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(dashboardFilterProvider);
    final currentType = widget.entityType;
    final hasActiveFilters = _hasActiveFilters(filters);
    final isStoreOpen = ref
        .watch(mainStoreProvider)
        .maybeWhen(data: (state) => state.isOpen, orElse: () => false);

    if (_searchController.text != filters.query) {
      _searchController.value = _searchController.value.copyWith(
        text: filters.query,
        selection: TextSelection.collapsed(offset: filters.query.length),
        composing: TextRange.empty,
      );
    }

    return SliverAppBar(
      expandedHeight: widget.expandedHeight,
      collapsedHeight: widget.collapsedHeight,
      backgroundColor: widget.isScrolled
          ? theme.scaffoldBackgroundColor
          : Colors.transparent,
      surfaceTintColor: Colors.transparent,
      pinned: widget.pinned,
      floating: widget.floating,
      snap: widget.snap,
      elevation: 0,
      leading: widget.onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onMenuPressed,
              tooltip: 'Открыть меню',
            )
          : null,
      actions: [
        if (widget.showEntityTypeSelector)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DashboardV2EntityTypeCompactDropdown(
              currentType: currentType,
              onEntityTypeChanged: widget.onEntityTypeChanged,
            ),
          ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _openFilter,
          tooltip: 'Открыть фильтры',
        ),
        PopupMenuButton<_DashboardMenuAction>(
          icon: const Icon(LucideIcons.settings),
          tooltip: 'Меню хранилища',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (action) async {
            switch (action) {
              case _DashboardMenuAction.storeSettings:
                await _openStoreSettingsModal();
                break;
              case _DashboardMenuAction.pinnedEntityTypes:
                await _openPinnedEntityTypesModal();
                break;
              case _DashboardMenuAction.backupNow:
                if (isStoreOpen) {
                  await _createBackupNow();
                } else {
                  Toaster.warning(
                    title: 'Бэкап недоступен',
                    description: 'Сначала откройте хранилище',
                  );
                }
                break;
              case _DashboardMenuAction.keepassImport:
                if (context.mounted) context.go(AppRoutesPaths.keepassImport);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.storeSettings,
              child: Row(
                children: [
                  Icon(LucideIcons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Настройки хранилища'),
                ],
              ),
            ),
            const PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.pinnedEntityTypes,
              child: Row(
                children: [
                  Icon(Icons.push_pin_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Типы записей в навигации'),
                ],
              ),
            ),
            PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.backupNow,
              enabled: isStoreOpen,
              child: const Row(
                children: [
                  Icon(Icons.backup, size: 20),
                  SizedBox(width: 8),
                  Text('Бэкап сейчас'),
                ],
              ),
            ),
            const PopupMenuItem<_DashboardMenuAction>(
              value: _DashboardMenuAction.keepassImport,
              child: Row(
                children: [
                  Icon(LucideIcons.import, size: 20),
                  SizedBox(width: 8),
                  Text('Импорт данных из KeePass'),
                ],
              ),
            ),
          ],
        ),
        if (widget.additionalActions != null) ...widget.additionalActions!,
        const SizedBox(width: 8),
      ],
      title: Text(
        currentType.label,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            height: 50,
                            child: PrimaryTextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              hintText: _getSearchHint(currentType),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              decoration:
                                  primaryInputDecoration(
                                    context,
                                    hintText: _getSearchHint(currentType),
                                  ).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        DashboardV2FilterTabs(
                          height: 40,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          borderRadius: 16,
                          onTabChanged: (tab) {
                            logInfo(
                              'DashboardV2SliverAppBar: Изменена вкладка',
                              data: {'tab': tab.label},
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    ref.read(dashboardFilterProvider.notifier).setQuery(query);
    logDebug(
      'DashboardV2SliverAppBar: Обновлен поисковый запрос',
      data: {'query': query},
    );
  }

  Future<void> _openFilter() async {
    logInfo('DashboardV2SliverAppBar: Открытие фильтров');
    if (widget.onFilterPressed != null) {
      widget.onFilterPressed?.call();
      return;
    } else {
      await FilterModal.show(
        context: context,
        entityType: widget.entityType,
        onFilterApplied: widget.onFilterApplied,
      );
    }
  }

  bool _hasActiveFilters(DashboardFilterState filters) {
    final hasDashboardFilters =
        filters.query.isNotEmpty || filters.tab != DashboardFilterTab.active;
    return hasDashboardFilters || _hasEntityFilterConstraints();
  }

  bool _hasEntityFilterConstraints() {
    return switch (widget.entityType) {
      DashboardEntityType.password =>
        ref.watch(passwordsFilterProvider).hasActiveConstraints,
      DashboardEntityType.note =>
        ref.watch(notesFilterProvider).hasActiveConstraints,
      DashboardEntityType.otp =>
        ref.watch(otpsFilterProvider).hasActiveConstraints,
      DashboardEntityType.bankCard =>
        ref.watch(bankCardsFilterProvider).hasActiveConstraints,
      DashboardEntityType.file =>
        ref.watch(filesFilterProvider).hasActiveConstraints,
      DashboardEntityType.document =>
        ref.watch(documentsFilterProvider).hasActiveConstraints,
      DashboardEntityType.contact =>
        ref.watch(contactsFilterProvider).hasActiveConstraints,
      DashboardEntityType.apiKey =>
        ref.watch(apiKeysFilterProvider).hasActiveConstraints,
      DashboardEntityType.sshKey =>
        ref.watch(sshKeysFilterProvider).hasActiveConstraints,
      DashboardEntityType.certificate =>
        ref.watch(certificatesFilterProvider).hasActiveConstraints,
      DashboardEntityType.cryptoWallet =>
        ref.watch(cryptoWalletsFilterProvider).hasActiveConstraints,
      DashboardEntityType.wifi =>
        ref.watch(wifisFilterProvider).hasActiveConstraints,
      DashboardEntityType.identity =>
        ref.watch(identitiesFilterProvider).hasActiveConstraints,
      DashboardEntityType.licenseKey =>
        ref.watch(licenseKeysFilterProvider).hasActiveConstraints,
      DashboardEntityType.recoveryCodes =>
        ref.watch(recoveryCodesFilterProvider).hasActiveConstraints,
      DashboardEntityType.loyaltyCard =>
        ref.watch(loyaltyCardsFilterProvider).hasActiveConstraints,
    };
  }

  Future<void> _openStoreSettingsModal() async {
    logInfo('DashboardV2SliverAppBar: Открытие настроек хранилища');
    await showStoreSettingsModal(context);
  }

  Future<void> _openPinnedEntityTypesModal() async {
    logInfo('DashboardV2SliverAppBar: Открытие настроек типов записей');
    await showPinnedEntityTypesModal(context);
  }

  BackupScope _parseBackupScope(String? raw) {
    return switch (raw) {
      'databaseOnly' => BackupScope.databaseOnly,
      'encryptedFilesOnly' => BackupScope.encryptedFilesOnly,
      _ => BackupScope.full,
    };
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

  String _getSearchHint(DashboardEntityType entityType) {
    return switch (entityType) {
      DashboardEntityType.password =>
        'Поиск паролей по названию, URL, пользователю...',
      DashboardEntityType.note => 'Поиск заметок по заголовку, содержимому...',
      DashboardEntityType.otp => 'Поиск OTP по издателю, аккаунту...',
      DashboardEntityType.bankCard => 'Поиск карт по названию, номеру...',
      DashboardEntityType.file => 'Поиск файлов по имени...',
      DashboardEntityType.document => 'Поиск документов по названию, типу...',
      DashboardEntityType.contact =>
        'Поиск контактов по имени, компании, телефону...',
      DashboardEntityType.apiKey =>
        'Поиск API-ключей по сервису, типу токена...',
      DashboardEntityType.sshKey =>
        'Поиск SSH-ключей по комментарию, отпечатку...',
      DashboardEntityType.certificate =>
        'Поиск сертификатов по issuer, subject...',
      DashboardEntityType.cryptoWallet => 'Поиск кошельков по сети, адресу...',
      DashboardEntityType.wifi => 'Поиск Wi-Fi по SSID, security...',
      DashboardEntityType.identity => 'Поиск ID по типу документа, номеру...',
      DashboardEntityType.licenseKey => 'Поиск лицензий по продукту, ключу...',
      DashboardEntityType.recoveryCodes =>
        'Поиск recovery codes по заметкам...',
      DashboardEntityType.loyaltyCard =>
        'Поиск карт лояльности по названию, номеру...',
    };
  }
}
