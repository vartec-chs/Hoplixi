import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard_v2/dashboard_v2.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'package:hoplixi/main_db/core/models/filter/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

// Модели и провайдеры
import '../../providers/filter_providers/api_keys_filter_provider.dart';
import '../../providers/filter_providers/bank_cards_filter_provider.dart';
import '../../providers/filter_providers/base_filter_provider.dart';
import '../../providers/filter_providers/certificates_filter_provider.dart';
import '../../providers/filter_providers/contacts_filter_provider.dart';
import '../../providers/filter_providers/crypto_wallets_filter_provider.dart';
import '../../providers/filter_providers/documents_filter_provider.dart';
import '../../providers/filter_providers/files_filter_provider.dart';
import '../../providers/filter_providers/identities_filter_provider.dart';
import '../../providers/filter_providers/license_keys_filter_provider.dart';
import '../../providers/filter_providers/loyalty_cards_filter_provider.dart';
import '../../providers/filter_providers/notes_filter_provider.dart';
import '../../providers/filter_providers/otp_filter_provider.dart';
import '../../providers/filter_providers/password_filter_provider.dart';
import '../../providers/filter_providers/recovery_codes_filter_provider.dart';
import '../../providers/filter_providers/ssh_keys_filter_provider.dart';
import '../../providers/filter_providers/wifis_filter_provider.dart';
// Секции фильтров
import 'filters_section/filter_sections.dart';

/// Типобезопасное хранилище начальных значений фильтров
class _InitialFilterValues {
  final BaseFilter baseFilter;
  final PasswordsFilter? passwordsFilter;
  final NotesFilter? notesFilter;
  final OtpsFilter? otpsFilter;
  final BankCardsFilter? bankCardsFilter;
  final FilesFilter? filesFilter;
  final DocumentsFilter? documentsFilter;
  final ContactsFilter? contactsFilter;
  final ApiKeysFilter? apiKeysFilter;
  final SshKeysFilter? sshKeysFilter;
  final CertificatesFilter? certificatesFilter;
  final CryptoWalletsFilter? cryptoWalletsFilter;
  final WifisFilter? wifisFilter;
  final IdentitiesFilter? identitiesFilter;
  final LicenseKeysFilter? licenseKeysFilter;
  final RecoveryCodesFilter? recoveryCodesFilter;
  final LoyaltyCardsFilter? loyaltyCardsFilter;

  _InitialFilterValues({
    required this.baseFilter,
    this.passwordsFilter,
    this.notesFilter,
    this.otpsFilter,
    this.bankCardsFilter,
    this.filesFilter,
    this.documentsFilter,
    this.contactsFilter,
    this.apiKeysFilter,
    this.sshKeysFilter,
    this.certificatesFilter,
    this.cryptoWalletsFilter,
    this.wifisFilter,
    this.identitiesFilter,
    this.licenseKeysFilter,
    this.recoveryCodesFilter,
    this.loyaltyCardsFilter,
  });
}

/// Модальное окно фильтра на базе WoltModalSheet
/// Адаптируется под выбранный тип сущности
class FilterModal {
  FilterModal._();

  /// Показать модальное окно фильтра
  static Future<void> show({
    required BuildContext context,
    required DashboardEntityType entityType,
    VoidCallback? onFilterApplied,
  }) async {
    logDebug('FilterModal: Открытие модального окна фильтра');

    await WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,

      pageListBuilder: (modalSheetContext) {
        return [
          _buildMainFilterPage(modalSheetContext, entityType, onFilterApplied),
        ];
      },
    );
  }

  /// Построить главную страницу фильтра
  static WoltModalSheetPage _buildMainFilterPage(
    BuildContext context,
    DashboardEntityType entityType,
    VoidCallback? onFilterApplied,
  ) {
    // Глобальный ключ для доступа к состоянию _FilterModalContent
    final GlobalKey<_FilterModalContentState> contentKey = GlobalKey();

    return WoltModalSheetPage(
      hasTopBarLayer: true,
      forceMaxHeight: true,

      isTopBarLayerAlwaysVisible: true,
      topBarTitle: Consumer(
        builder: (context, ref, _) {
          return Text(
            'Фильтры: ${entityType.label}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          );
        },
      ),
      leadingNavBarWidget: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: ModalSheetCloseButton(),
      ),
      trailingNavBarWidget: Consumer(
        builder: (context, ref, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _FilterModalActions(
              contentKey: contentKey,
              entityType: entityType,
              onFilterApplied: onFilterApplied,
            ),
          );
        },
      ),

      child: _FilterModalContent(
        key: contentKey,
        entityType: entityType,
        onFilterApplied: onFilterApplied,
      ),
    );
  }
}

/// Кнопки действий в навигационной панели модального окна фильтра
class _FilterModalActions extends ConsumerWidget {
  const _FilterModalActions({
    required this.contentKey,
    required this.entityType,
    this.onFilterApplied,
  });

  final GlobalKey<_FilterModalContentState> contentKey;
  final DashboardEntityType entityType;
  final VoidCallback? onFilterApplied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveFilters = _hasActiveFilters(ref, entityType);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Кнопка сброса
        if (hasActiveFilters) ...[
          SmoothButton(
            onPressed: () => _resetFilters(ref, entityType),
            icon: const Icon(Icons.clear_all, size: 18),
            label: 'Сбросить',
            type: SmoothButtonType.outlined,
            size: SmoothButtonSize.small,
          ),
          const SizedBox(width: 8),
        ],

        // Кнопка применения
        IconButton(
          onPressed: () => _applyAndClose(context, onFilterApplied),
          icon: const Icon(Icons.check, size: 24),
          tooltip: 'Применить фильтры',
        ),
      ],
    );
  }

  bool _hasActiveFilters(WidgetRef ref, DashboardEntityType entityType) {
    return switch (entityType) {
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
      DashboardEntityType.apiKey =>
        ref.watch(apiKeysFilterProvider).hasActiveConstraints,
      DashboardEntityType.contact =>
        ref.watch(contactsFilterProvider).hasActiveConstraints,
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

  void _resetFilters(WidgetRef ref, DashboardEntityType entityType) {
    logDebug('FilterModal: Сброс всех фильтров через действие в панели');

    try {
      // Проверяем состояние контента
      final contentState = contentKey.currentState;
      if (contentState == null || !contentState.mounted) {
        logWarning('FilterModal: Контент не доступен для сброса');
        return;
      }

      final emptyBaseFilter = const BaseFilter();

      // Сброс базового фильтра
      ref.read(baseFilterProvider.notifier).updateFilter(emptyBaseFilter);

      // Сброс специфичных фильтров
      switch (entityType) {
        case DashboardEntityType.password:
          ref
              .read(passwordsFilterProvider.notifier)
              .updateFilter(PasswordsFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.note:
          ref
              .read(notesFilterProvider.notifier)
              .updateFilter(NotesFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.otp:
          ref
              .read(otpsFilterProvider.notifier)
              .updateFilter(OtpsFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.bankCard:
          ref
              .read(bankCardsFilterProvider.notifier)
              .updateFilter(BankCardsFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.file:
          ref
              .read(filesFilterProvider.notifier)
              .updateFilter(FilesFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.document:
          ref
              .read(documentsFilterProvider.notifier)
              .updateFilter(DocumentsFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.apiKey:
          ref
              .read(apiKeysFilterProvider.notifier)
              .updateFilter(ApiKeysFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.contact:
          ref
              .read(contactsFilterProvider.notifier)
              .updateFilter(ContactsFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.sshKey:
          ref
              .read(sshKeysFilterProvider.notifier)
              .updateFilter(SshKeysFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.certificate:
          ref
              .read(certificatesFilterProvider.notifier)
              .updateFilter(CertificatesFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.cryptoWallet:
          ref
              .read(cryptoWalletsFilterProvider.notifier)
              .updateFilter(CryptoWalletsFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.wifi:
          ref
              .read(wifisFilterProvider.notifier)
              .updateFilter(WifisFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.identity:
          ref
              .read(identitiesFilterProvider.notifier)
              .updateFilter(IdentitiesFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.licenseKey:
          ref
              .read(licenseKeysFilterProvider.notifier)
              .updateFilter(LicenseKeysFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.recoveryCodes:
          ref
              .read(recoveryCodesFilterProvider.notifier)
              .updateFilter(RecoveryCodesFilter(base: emptyBaseFilter));
          break;
        case DashboardEntityType.loyaltyCard:
          ref
              .read(loyaltyCardsFilterProvider.notifier)
              .updateFilter(LoyaltyCardsFilter(base: emptyBaseFilter));
          break;
      }

      contentState.clearFields();

      logInfo('FilterModal: Фильтры сброшены через панель действий');
    } catch (e) {
      logError('FilterModal: Ошибка при сбросе фильтров', error: e);
    }
  }

  void _applyAndClose(BuildContext context, VoidCallback? onFilterApplied) {
    logDebug('FilterModal: Применение фильтров и закрытие модального окна');

    try {
      // Получаем состояние контента для доступа к локальным фильтрам
      final contentState = contentKey.currentState;
      if (contentState == null || !contentState.mounted) {
        logError(
          'FilterModal: Не удалось получить состояние контента или виджет не mounted',
        );
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Применяем локальные фильтры
      contentState.applyLocalFiltersToProviders();

      // Вызываем callback перед закрытием
      onFilterApplied?.call();

      // Закрываем модалку с небольшой задержкой чтобы избежать конфликтов
      if (context.mounted) {
        Future.microtask(() {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e, stackTrace) {
      logError(
        'FilterModal: Ошибка при применении и закрытии',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Основное содержимое модального окна фильтра
class _FilterModalContent extends ConsumerStatefulWidget {
  const _FilterModalContent({
    super.key,
    required this.entityType,
    this.onFilterApplied,
  });

  final DashboardEntityType entityType;
  final VoidCallback? onFilterApplied;

  @override
  ConsumerState<_FilterModalContent> createState() =>
      _FilterModalContentState();
}

class _FilterModalContentState extends ConsumerState<_FilterModalContent> {
  // Состояние для выбранных категорий и тегов
  List<String> _selectedCategoryIds = [];
  List<String> _selectedCategoryNames = [];
  List<String> _selectedTagIds = [];
  List<String> _selectedTagNames = [];

  // Локальные копии фильтров (изменяются локально, применяются при нажатии кнопки)
  late BaseFilter _localBaseFilter;
  PasswordsFilter? _localPasswordsFilter;
  NotesFilter? _localNotesFilter;
  OtpsFilter? _localOtpsFilter;
  BankCardsFilter? _localBankCardsFilter;
  FilesFilter? _localFilesFilter;
  DocumentsFilter? _localDocumentsFilter;
  ContactsFilter? _localContactsFilter;
  ApiKeysFilter? _localApiKeysFilter;
  SshKeysFilter? _localSshKeysFilter;
  CertificatesFilter? _localCertificatesFilter;
  CryptoWalletsFilter? _localCryptoWalletsFilter;
  WifisFilter? _localWifisFilter;
  IdentitiesFilter? _localIdentitiesFilter;
  LicenseKeysFilter? _localLicenseKeysFilter;
  RecoveryCodesFilter? _localRecoveryCodesFilter;
  LoyaltyCardsFilter? _localLoyaltyCardsFilter;

  // Типобезопасное хранение начальных значений для отката
  _InitialFilterValues? _initialValues;

  @override
  void initState() {
    super.initState();
    // Инициализируем фильтры синхронно, чтобы избежать LateInitializationError
    _initializeLocalFilters();
    _loadInitialValues();
    logDebug('FilterModal: Инициализация содержимого фильтра');
  }

  void _initializeLocalFilters() {
    final entityType = widget.entityType;
    _localBaseFilter = ref.read(baseFilterProvider);

    // Инициализируем категории и теги из базового фильтра
    _selectedCategoryIds = List<String>.from(_localBaseFilter.categoryIds);
    _selectedTagIds = List<String>.from(_localBaseFilter.tagIds);

    switch (entityType) {
      case DashboardEntityType.password:
        _localPasswordsFilter = ref.read(passwordsFilterProvider);
        break;
      case DashboardEntityType.note:
        _localNotesFilter = ref.read(notesFilterProvider);
        break;
      case DashboardEntityType.otp:
        _localOtpsFilter = ref.read(otpsFilterProvider);
        break;
      case DashboardEntityType.bankCard:
        _localBankCardsFilter = ref.read(bankCardsFilterProvider);
        break;
      case DashboardEntityType.file:
        _localFilesFilter = ref.read(filesFilterProvider);
        break;

      case DashboardEntityType.document:
        _localDocumentsFilter = ref.read(documentsFilterProvider);
        break;
      case DashboardEntityType.apiKey:
        _localApiKeysFilter = ref.read(apiKeysFilterProvider);
        break;
      case DashboardEntityType.contact:
        _localContactsFilter = ref.read(contactsFilterProvider);
        break;
      case DashboardEntityType.sshKey:
        _localSshKeysFilter = ref.read(sshKeysFilterProvider);
        break;
      case DashboardEntityType.certificate:
        _localCertificatesFilter = ref.read(certificatesFilterProvider);
        break;
      case DashboardEntityType.cryptoWallet:
        _localCryptoWalletsFilter = ref.read(cryptoWalletsFilterProvider);
        break;
      case DashboardEntityType.wifi:
        _localWifisFilter = ref.read(wifisFilterProvider);
        break;
      case DashboardEntityType.identity:
        _localIdentitiesFilter = ref.read(identitiesFilterProvider);
        break;
      case DashboardEntityType.licenseKey:
        _localLicenseKeysFilter = ref.read(licenseKeysFilterProvider);
        break;
      case DashboardEntityType.recoveryCodes:
        _localRecoveryCodesFilter = ref.read(recoveryCodesFilterProvider);
        break;
      case DashboardEntityType.loyaltyCard:
        _localLoyaltyCardsFilter = ref.read(loyaltyCardsFilterProvider);
        break;
    }

    // Загружаем имена категорий и тегов в postFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCategoryAndTagNames();
    });
  }

  void _loadInitialValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _saveInitialValues();
    });
  }

  void _saveInitialValues() {
    if (!mounted) return; // Дополнительная проверка

    final entityType = widget.entityType;
    final baseFilter = ref.read(baseFilterProvider);

    // Сохраняем специфичные для типа значения
    switch (entityType) {
      case DashboardEntityType.password:
        final passwordFilter = ref.read(passwordsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          passwordsFilter: passwordFilter,
        );
        break;

      case DashboardEntityType.document:
        final documentsFilter = ref.read(documentsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          documentsFilter: documentsFilter,
        );
        break;

      case DashboardEntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          notesFilter: notesFilter,
        );
        break;

      case DashboardEntityType.otp:
        final otpFilter = ref.read(otpsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          otpsFilter: otpFilter,
        );
        break;

      case DashboardEntityType.bankCard:
        final bankCardsFilter = ref.read(bankCardsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          bankCardsFilter: bankCardsFilter,
        );
        break;

      case DashboardEntityType.file:
        final filesFilter = ref.read(filesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          filesFilter: filesFilter,
        );
        break;
      case DashboardEntityType.apiKey:
        final apiKeysFilter = ref.read(apiKeysFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          apiKeysFilter: apiKeysFilter,
        );
        break;
      case DashboardEntityType.contact:
        final contactsFilter = ref.read(contactsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          contactsFilter: contactsFilter,
        );
        break;
      case DashboardEntityType.sshKey:
        final sshKeysFilter = ref.read(sshKeysFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          sshKeysFilter: sshKeysFilter,
        );
        break;
      case DashboardEntityType.certificate:
        final certificatesFilter = ref.read(certificatesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          certificatesFilter: certificatesFilter,
        );
        break;
      case DashboardEntityType.cryptoWallet:
        final cryptoWalletsFilter = ref.read(cryptoWalletsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          cryptoWalletsFilter: cryptoWalletsFilter,
        );
        break;
      case DashboardEntityType.wifi:
        final wifisFilter = ref.read(wifisFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          wifisFilter: wifisFilter,
        );
        break;
      case DashboardEntityType.identity:
        final identitiesFilter = ref.read(identitiesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          identitiesFilter: identitiesFilter,
        );
        break;
      case DashboardEntityType.licenseKey:
        final licenseKeysFilter = ref.read(licenseKeysFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          licenseKeysFilter: licenseKeysFilter,
        );
        break;
      case DashboardEntityType.recoveryCodes:
        final recoveryCodesFilter = ref.read(recoveryCodesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          recoveryCodesFilter: recoveryCodesFilter,
        );
        break;
      case DashboardEntityType.loyaltyCard:
        final loyaltyCardsFilter = ref.read(loyaltyCardsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          loyaltyCardsFilter: loyaltyCardsFilter,
        );
        break;
    }

    logDebug(
      'FilterModal: Сохранены начальные значения',
      data: {
        'entityType': entityType.id,
        'hasBaseFilter': _initialValues != null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entityType = widget.entityType;
    final windowHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        minHeight: UniversalPlatform.isDesktop ? windowHeight * 0.90 : 0,
        maxHeight: UniversalPlatform.isDesktop
            ? windowHeight * 0.90
            : double.infinity,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          // Прокручиваемый контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // Секция категорий
                  _buildCategoriesSection(entityType),
                  const SizedBox(height: 24),

                  // Секция тегов
                  _buildTagsSection(entityType),
                  const SizedBox(height: 24),

                  // Базовые фильтры
                  _buildBaseFiltersSection(entityType),
                  const SizedBox(height: 24),

                  // Специфичные фильтры для типа сущности
                  _buildSpecificFiltersSection(entityType),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Кнопки перенесены в trailingNavBarWidget
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(DashboardEntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категории',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        CategoryPickerField(
          isFilter: true,
          selectedCategoryIds: _selectedCategoryIds,
          selectedCategoryNames: _selectedCategoryNames,
          filterByType: [_getCategoryType(entityType), CategoryType.mixed],
          onCategoriesSelected: (ids, names) {
            setState(() {
              _selectedCategoryIds = ids;
              _selectedCategoryNames = names;
              _localBaseFilter = _localBaseFilter.copyWith(categoryIds: ids);
            });
            logDebug(
              'FilterModal: Выбраны категории локально',
              data: {'count': ids.length},
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection(DashboardEntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Теги',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TagPickerField(
          isFilter: true,
          selectedTagIds: _selectedTagIds,
          selectedTagNames: _selectedTagNames,
          filterByType: [_getTagType(entityType), TagType.mixed],
          onTagsSelected: (ids, names) {
            setState(() {
              _selectedTagIds = ids;
              _selectedTagNames = names;
              _localBaseFilter = _localBaseFilter.copyWith(tagIds: ids);
            });
            logDebug(
              'FilterModal: Выбраны теги локально',
              data: {'count': ids.length},
            );
          },
        ),
      ],
    );
  }

  Widget _buildBaseFiltersSection(DashboardEntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Общие фильтры',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        BaseFilterSection(
          filter: _localBaseFilter,
          entityTypeName: entityType.label,
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localBaseFilter = updatedFilter;

              // Обновляем base в специфичном фильтре текущего типа
              switch (entityType) {
                case DashboardEntityType.password:
                  if (_localPasswordsFilter != null) {
                    _localPasswordsFilter = _localPasswordsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.note:
                  if (_localNotesFilter != null) {
                    _localNotesFilter = _localNotesFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.otp:
                  if (_localOtpsFilter != null) {
                    _localOtpsFilter = _localOtpsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.bankCard:
                  if (_localBankCardsFilter != null) {
                    _localBankCardsFilter = _localBankCardsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.file:
                  if (_localFilesFilter != null) {
                    _localFilesFilter = _localFilesFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.document:
                  if (_localDocumentsFilter != null) {
                    _localDocumentsFilter = _localDocumentsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.apiKey:
                  if (_localApiKeysFilter != null) {
                    _localApiKeysFilter = _localApiKeysFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.contact:
                  if (_localContactsFilter != null) {
                    _localContactsFilter = _localContactsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.sshKey:
                  if (_localSshKeysFilter != null) {
                    _localSshKeysFilter = _localSshKeysFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.certificate:
                  if (_localCertificatesFilter != null) {
                    _localCertificatesFilter = _localCertificatesFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
                case DashboardEntityType.cryptoWallet:
                  if (_localCryptoWalletsFilter != null) {
                    _localCryptoWalletsFilter = _localCryptoWalletsFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
                case DashboardEntityType.wifi:
                  if (_localWifisFilter != null) {
                    _localWifisFilter = _localWifisFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.identity:
                  if (_localIdentitiesFilter != null) {
                    _localIdentitiesFilter = _localIdentitiesFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.licenseKey:
                  if (_localLicenseKeysFilter != null) {
                    _localLicenseKeysFilter = _localLicenseKeysFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case DashboardEntityType.recoveryCodes:
                  if (_localRecoveryCodesFilter != null) {
                    _localRecoveryCodesFilter = _localRecoveryCodesFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
                case DashboardEntityType.loyaltyCard:
                  if (_localLoyaltyCardsFilter != null) {
                    _localLoyaltyCardsFilter = _localLoyaltyCardsFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
              }
            });
            logDebug('FilterModal: Обновлены базовые фильтры локально');
          },
        ),
      ],
    );
  }

  Widget _buildSpecificFiltersSection(DashboardEntityType entityType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильтры ${entityType.label.toLowerCase()}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildEntitySpecificSection(entityType),
      ],
    );
  }

  Widget _buildEntitySpecificSection(DashboardEntityType entityType) {
    switch (entityType) {
      case DashboardEntityType.password:
        return PasswordFilterSection(
          filter:
              _localPasswordsFilter ?? PasswordsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localPasswordsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры паролей локально');
          },
        );

      case DashboardEntityType.note:
        return NotesFilterSection(
          filter: _localNotesFilter ?? NotesFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localNotesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры заметок локально');
          },
        );

      case DashboardEntityType.otp:
        return OtpsFilterSection(
          filter: _localOtpsFilter ?? OtpsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localOtpsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры OTP локально');
          },
        );

      case DashboardEntityType.bankCard:
        return BankCardsFilterSection(
          filter:
              _localBankCardsFilter ?? BankCardsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localBankCardsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры банковских карт локально');
          },
        );

      case DashboardEntityType.file:
        return FilesFilterSection(
          filter: _localFilesFilter ?? FilesFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localFilesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры файлов локально');
          },
        );

      case DashboardEntityType.document:
        return DocumentsFilterSection(
          filter:
              _localDocumentsFilter ?? DocumentsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localDocumentsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры документов локально');
          },
        );
      case DashboardEntityType.apiKey:
        return ApiKeysFilterSection(
          filter: _localApiKeysFilter ?? ApiKeysFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localApiKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры API-ключей локально');
          },
        );
      case DashboardEntityType.contact:
        return ContactsFilterSection(
          filter:
              _localContactsFilter ?? ContactsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localContactsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры контактов локально');
          },
        );
      case DashboardEntityType.sshKey:
        return SshKeysFilterSection(
          filter: _localSshKeysFilter ?? SshKeysFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localSshKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры SSH-ключей локально');
          },
        );
      case DashboardEntityType.certificate:
        return CertificatesFilterSection(
          filter:
              _localCertificatesFilter ??
              CertificatesFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localCertificatesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры сертификатов локально');
          },
        );
      case DashboardEntityType.cryptoWallet:
        return CryptoWalletsFilterSection(
          filter:
              _localCryptoWalletsFilter ??
              CryptoWalletsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localCryptoWalletsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры криптокошельков локально');
          },
        );
      case DashboardEntityType.wifi:
        return WifisFilterSection(
          filter: _localWifisFilter ?? WifisFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localWifisFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры Wi-Fi локально');
          },
        );
      case DashboardEntityType.identity:
        return IdentitiesFilterSection(
          filter:
              _localIdentitiesFilter ??
              IdentitiesFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localIdentitiesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры идентификаций локально');
          },
        );
      case DashboardEntityType.licenseKey:
        return LicenseKeysFilterSection(
          filter:
              _localLicenseKeysFilter ??
              LicenseKeysFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localLicenseKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры лицензий локально');
          },
        );
      case DashboardEntityType.recoveryCodes:
        return RecoveryCodesFilterSection(
          filter:
              _localRecoveryCodesFilter ??
              RecoveryCodesFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localRecoveryCodesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры recovery codes локально');
          },
        );
      case DashboardEntityType.loyaltyCard:
        return LoyaltyCardsFilterSection(
          filter:
              _localLoyaltyCardsFilter ??
              LoyaltyCardsFilter(base: _localBaseFilter),
          onChanged: (updatedFilter) {
            setState(() {
              _localLoyaltyCardsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры карт лояльности локально');
          },
        );
    }
  }

  CategoryType _getCategoryType(DashboardEntityType entityType) {
    switch (entityType) {
      case DashboardEntityType.document:
        return CategoryType.document;
      case DashboardEntityType.password:
        return CategoryType.password;
      case DashboardEntityType.note:
        return CategoryType.note;
      case DashboardEntityType.bankCard:
        return CategoryType.bankCard;
      case DashboardEntityType.file:
        return CategoryType.file;
      case DashboardEntityType.otp:
        return CategoryType.totp;
      case DashboardEntityType.apiKey:
        return CategoryType.apiKey;
      case DashboardEntityType.contact:
        return CategoryType.contact;
      case DashboardEntityType.sshKey:
        return CategoryType.sshKey;
      case DashboardEntityType.certificate:
        return CategoryType.certificate;
      case DashboardEntityType.cryptoWallet:
        return CategoryType.cryptoWallet;
      case DashboardEntityType.wifi:
        return CategoryType.wifi;
      case DashboardEntityType.identity:
        return CategoryType.identity;
      case DashboardEntityType.licenseKey:
        return CategoryType.licenseKey;
      case DashboardEntityType.recoveryCodes:
        return CategoryType.recoveryCodes;
      case DashboardEntityType.loyaltyCard:
        return CategoryType.loyaltyCard;
    }
  }

  TagType _getTagType(DashboardEntityType entityType) {
    switch (entityType) {
      case DashboardEntityType.document:
        return TagType.document;
      case DashboardEntityType.password:
        return TagType.password;
      case DashboardEntityType.note:
        return TagType.note;
      case DashboardEntityType.bankCard:
        return TagType.bankCard;
      case DashboardEntityType.file:
        return TagType.file;
      case DashboardEntityType.otp:
        return TagType.totp;
      case DashboardEntityType.apiKey:
        return TagType.apiKey;
      case DashboardEntityType.contact:
        return TagType.contact;
      case DashboardEntityType.sshKey:
        return TagType.sshKey;
      case DashboardEntityType.certificate:
        return TagType.certificate;
      case DashboardEntityType.cryptoWallet:
        return TagType.cryptoWallet;
      case DashboardEntityType.wifi:
        return TagType.wifi;
      case DashboardEntityType.identity:
        return TagType.identity;
      case DashboardEntityType.licenseKey:
        return TagType.licenseKey;
      case DashboardEntityType.recoveryCodes:
        return TagType.recoveryCodes;
      case DashboardEntityType.loyaltyCard:
        return TagType.loyaltyCard;
    }
  }

  /// Загрузить имена категорий и тегов по их ID
  Future<void> _loadCategoryAndTagNames() async {
    if (!mounted) return;

    try {
      // Загружаем имена категорий через DAO
      if (_selectedCategoryIds.isNotEmpty) {
        final categoryDao = await ref.read(categoryDaoProvider.future);
        final categoryNames = <String>[];

        for (final id in _selectedCategoryIds) {
          final category = await categoryDao.getCategoryById(id);
          if (category != null) {
            categoryNames.add(category.name);
          }
        }

        if (mounted) {
          setState(() {
            _selectedCategoryNames = categoryNames;
          });
        }
      }

      // Загружаем имена тегов через DAO
      if (_selectedTagIds.isNotEmpty) {
        final tagDao = await ref.read(tagDaoProvider.future);
        final tagNames = <String>[];

        for (final id in _selectedTagIds) {
          final tag = await tagDao.getTagById(id);
          if (tag != null) {
            tagNames.add(tag.name);
          }
        }

        if (mounted) {
          setState(() {
            _selectedTagNames = tagNames;
          });
        }
      }

      logDebug(
        'FilterModal: Загружены имена категорий и тегов',
        data: {
          'categories': _selectedCategoryNames.length,
          'tags': _selectedTagNames.length,
        },
      );
    } catch (e) {
      logError(
        'ФильтрModal: Ошибка при загрузке имён категорий/тегов',
        error: e,
      );
    }
  }

  /// Применить локальные фильтры к провайдерам
  void applyLocalFiltersToProviders() {
    if (!mounted) {
      logWarning(
        'FilterModal: Попытка применить фильтры к размонтированному виджету',
      );
      return;
    }

    logDebug('FilterModal: Применение локальных фильтров к провайдерам');

    try {
      final entityType = widget.entityType;

      // Применяем базовый фильтр
      final baseNotifier = ref.read(baseFilterProvider.notifier);
      baseNotifier.updateFilter(_localBaseFilter);

      // Синхронизируем base в специфичных фильтрах перед применением
      // чтобы категории и теги были актуальными
      switch (entityType) {
        case DashboardEntityType.password:
          if (_localPasswordsFilter != null) {
            final syncedFilter = _localPasswordsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.note:
          if (_localNotesFilter != null) {
            final syncedFilter = _localNotesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(notesFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.otp:
          if (_localOtpsFilter != null) {
            final syncedFilter = _localOtpsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(otpsFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.bankCard:
          if (_localBankCardsFilter != null) {
            final syncedFilter = _localBankCardsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.file:
          if (_localFilesFilter != null) {
            final syncedFilter = _localFilesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(filesFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;

        case DashboardEntityType.document:
          if (_localDocumentsFilter != null) {
            final syncedFilter = _localDocumentsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(documentsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.apiKey:
          if (_localApiKeysFilter != null) {
            final syncedFilter = _localApiKeysFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(apiKeysFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.contact:
          if (_localContactsFilter != null) {
            final syncedFilter = _localContactsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(contactsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.sshKey:
          if (_localSshKeysFilter != null) {
            final syncedFilter = _localSshKeysFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(sshKeysFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.certificate:
          if (_localCertificatesFilter != null) {
            final syncedFilter = _localCertificatesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(certificatesFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.cryptoWallet:
          if (_localCryptoWalletsFilter != null) {
            final syncedFilter = _localCryptoWalletsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(cryptoWalletsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.wifi:
          if (_localWifisFilter != null) {
            final syncedFilter = _localWifisFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(wifisFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.identity:
          if (_localIdentitiesFilter != null) {
            final syncedFilter = _localIdentitiesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(identitiesFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.licenseKey:
          if (_localLicenseKeysFilter != null) {
            final syncedFilter = _localLicenseKeysFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(licenseKeysFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.recoveryCodes:
          if (_localRecoveryCodesFilter != null) {
            final syncedFilter = _localRecoveryCodesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(recoveryCodesFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case DashboardEntityType.loyaltyCard:
          if (_localLoyaltyCardsFilter != null) {
            final syncedFilter = _localLoyaltyCardsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(loyaltyCardsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
      }

      logInfo('FilterModal: Локальные фильтры успешно применены к провайдерам');
    } catch (e) {
      logError('FilterModal: Ошибка при применении фильтров', error: e);
    }
  }

  /// Восстановить начальные значения фильтров (если нужен откат)
  /// Может быть использован для кнопки "Отменить изменения"
  // ignore: unused_element
  void _restoreInitialValues() {
    if (_initialValues == null) {
      logWarning(
        'FilterModal: Нет сохраненных начальных значений для восстановления',
      );
      return;
    }

    logDebug('FilterModal: Восстановление начальных значений фильтров');

    try {
      final entityType = widget.entityType;

      // Восстановление базового фильтра через методы notifier
      final baseNotifier = ref.read(baseFilterProvider.notifier);
      final base = _initialValues!.baseFilter;

      baseNotifier.updateFilter(base);

      // Восстановление специфичного для типа фильтра
      switch (entityType) {
        case DashboardEntityType.password:
          if (_initialValues!.passwordsFilter != null) {
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.passwordsFilter!);
          }
          break;
        case DashboardEntityType.note:
          if (_initialValues!.notesFilter != null) {
            ref
                .read(notesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.notesFilter!);
          }
          break;
        case DashboardEntityType.otp:
          if (_initialValues!.otpsFilter != null) {
            ref
                .read(otpsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.otpsFilter!);
          }
          break;
        case DashboardEntityType.bankCard:
          if (_initialValues!.bankCardsFilter != null) {
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.bankCardsFilter!);
          }
          break;
        case DashboardEntityType.file:
          if (_initialValues!.filesFilter != null) {
            ref
                .read(filesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.filesFilter!);
          }
          break;

        case DashboardEntityType.document:
          if (_initialValues!.documentsFilter != null) {
            ref
                .read(documentsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.documentsFilter!);
          }
          break;
        case DashboardEntityType.apiKey:
          if (_initialValues!.apiKeysFilter != null) {
            ref
                .read(apiKeysFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.apiKeysFilter!);
          }
          break;
        case DashboardEntityType.contact:
          if (_initialValues!.contactsFilter != null) {
            ref
                .read(contactsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.contactsFilter!);
          }
          break;
        case DashboardEntityType.sshKey:
          if (_initialValues!.sshKeysFilter != null) {
            ref
                .read(sshKeysFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.sshKeysFilter!);
          }
          break;
        case DashboardEntityType.certificate:
          if (_initialValues!.certificatesFilter != null) {
            ref
                .read(certificatesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.certificatesFilter!);
          }
          break;
        case DashboardEntityType.cryptoWallet:
          if (_initialValues!.cryptoWalletsFilter != null) {
            ref
                .read(cryptoWalletsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.cryptoWalletsFilter!);
          }
          break;
        case DashboardEntityType.wifi:
          if (_initialValues!.wifisFilter != null) {
            ref
                .read(wifisFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.wifisFilter!);
          }
          break;
        case DashboardEntityType.identity:
          if (_initialValues!.identitiesFilter != null) {
            ref
                .read(identitiesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.identitiesFilter!);
          }
          break;
        case DashboardEntityType.licenseKey:
          if (_initialValues!.licenseKeysFilter != null) {
            ref
                .read(licenseKeysFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.licenseKeysFilter!);
          }
          break;
        case DashboardEntityType.recoveryCodes:
          if (_initialValues!.recoveryCodesFilter != null) {
            ref
                .read(recoveryCodesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.recoveryCodesFilter!);
          }
          break;
        case DashboardEntityType.loyaltyCard:
          if (_initialValues!.loyaltyCardsFilter != null) {
            ref
                .read(loyaltyCardsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.loyaltyCardsFilter!);
          }
          break;
      }

      // Восстановление локального состояния
      setState(() {
        _selectedCategoryIds = List<String>.from(base.categoryIds);
        _selectedTagIds = List<String>.from(base.tagIds);
      });

      logInfo('FilterModal: Начальные значения восстановлены');
    } catch (e) {
      logError(
        'FilterModal: Ошибка при восстановлении начальных значений',
        error: e,
      );
    }
  }

  /// Очистить локальные поля фильтров
  void clearFields() {
    logDebug('FilterModal: Очистка локальных полей фильтров');

    setState(() {
      _selectedCategoryIds = [];
      _selectedCategoryNames = [];
      _selectedTagIds = [];
      _selectedTagNames = [];

      _localBaseFilter = const BaseFilter();

      switch (widget.entityType) {
        case DashboardEntityType.password:
          _localPasswordsFilter = PasswordsFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.note:
          _localNotesFilter = NotesFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.otp:
          _localOtpsFilter = OtpsFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.bankCard:
          _localBankCardsFilter = BankCardsFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.file:
          _localFilesFilter = FilesFilter(base: _localBaseFilter);
          break;

        case DashboardEntityType.document:
          _localDocumentsFilter = DocumentsFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.apiKey:
          _localApiKeysFilter = ApiKeysFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.contact:
          _localContactsFilter = ContactsFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.sshKey:
          _localSshKeysFilter = SshKeysFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.certificate:
          _localCertificatesFilter = CertificatesFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.cryptoWallet:
          _localCryptoWalletsFilter = CryptoWalletsFilter(
            base: _localBaseFilter,
          );
          break;
        case DashboardEntityType.wifi:
          _localWifisFilter = WifisFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.identity:
          _localIdentitiesFilter = IdentitiesFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.licenseKey:
          _localLicenseKeysFilter = LicenseKeysFilter(base: _localBaseFilter);
          break;
        case DashboardEntityType.recoveryCodes:
          _localRecoveryCodesFilter = RecoveryCodesFilter(
            base: _localBaseFilter,
          );
          break;
        case DashboardEntityType.loyaltyCard:
          _localLoyaltyCardsFilter = LoyaltyCardsFilter(base: _localBaseFilter);
          break;
      }
    });

    logInfo('FilterModal: Локальные поля фильтров очищены');
  }
}
