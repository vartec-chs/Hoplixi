import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/providers/repository_providers.dart';
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
  final PasswordFilter? passwordsFilter;
  final NoteFilter? notesFilter;
  final OtpFilter? otpsFilter;
  final BankCardFilter? bankCardsFilter;
  final FileFilter? filesFilter;
  final DocumentFilter? documentsFilter;
  final ContactFilter? contactsFilter;
  final ApiKeyFilter? apiKeysFilter;
  final SshKeyFilter? sshKeysFilter;
  final CertificateFilter? certificatesFilter;
  final CryptoWalletFilter? cryptoWalletsFilter;
  final WifiFilter? wifisFilter;
  final IdentityFilter? identitiesFilter;
  final LicenseKeyFilter? licenseKeysFilter;
  final RecoveryCodesFilter? recoveryCodesFilter;
  final LoyaltyCardFilter? loyaltyCardsFilter;

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
    required EntityType entityType,
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
    EntityType entityType,
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
  final EntityType entityType;
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

  bool _hasActiveFilters(WidgetRef ref, EntityType entityType) {
    return switch (entityType) {
      EntityType.password =>
        ref.watch(passwordsFilterProvider).hasActiveConstraints,
      EntityType.note => ref.watch(notesFilterProvider).hasActiveConstraints,
      EntityType.otp => ref.watch(otpsFilterProvider).hasActiveConstraints,
      EntityType.bankCard =>
        ref.watch(bankCardsFilterProvider).hasActiveConstraints,
      EntityType.file => ref.watch(filesFilterProvider).hasActiveConstraints,
      EntityType.document =>
        ref.watch(documentsFilterProvider).hasActiveConstraints,
      EntityType.apiKey =>
        ref.watch(apiKeysFilterProvider).hasActiveConstraints,
      EntityType.contact =>
        ref.watch(contactsFilterProvider).hasActiveConstraints,
      EntityType.sshKey =>
        ref.watch(sshKeysFilterProvider).hasActiveConstraints,
      EntityType.certificate =>
        ref.watch(certificatesFilterProvider).hasActiveConstraints,
      EntityType.cryptoWallet =>
        ref.watch(cryptoWalletsFilterProvider).hasActiveConstraints,
      EntityType.wifi => ref.watch(wifisFilterProvider).hasActiveConstraints,
      EntityType.identity =>
        ref.watch(identitiesFilterProvider).hasActiveConstraints,
      EntityType.licenseKey =>
        ref.watch(licenseKeysFilterProvider).hasActiveConstraints,
      EntityType.recoveryCodes =>
        ref.watch(recoveryCodesFilterProvider).hasActiveConstraints,
      EntityType.loyaltyCard =>
        ref.watch(loyaltyCardsFilterProvider).hasActiveConstraints,
    };
  }

  void _resetFilters(WidgetRef ref, EntityType entityType) {
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
        case EntityType.password:
          ref
              .read(passwordsFilterProvider.notifier)
              .updateFilter(PasswordFilter(base: emptyBaseFilter));
          break;
        case EntityType.note:
          ref
              .read(notesFilterProvider.notifier)
              .updateFilter(NoteFilter(base: emptyBaseFilter));
          break;
        case EntityType.otp:
          ref
              .read(otpsFilterProvider.notifier)
              .updateFilter(OtpFilter(base: emptyBaseFilter));
          break;
        case EntityType.bankCard:
          ref
              .read(bankCardsFilterProvider.notifier)
              .updateFilter(BankCardFilter(base: emptyBaseFilter));
          break;
        case EntityType.file:
          ref
              .read(filesFilterProvider.notifier)
              .updateFilter(FileFilter(base: emptyBaseFilter));
          break;
        case EntityType.document:
          ref
              .read(documentsFilterProvider.notifier)
              .updateFilter(DocumentFilter(base: emptyBaseFilter));
          break;
        case EntityType.apiKey:
          ref
              .read(apiKeysFilterProvider.notifier)
              .updateFilter(ApiKeyFilter(base: emptyBaseFilter));
          break;
        case EntityType.contact:
          ref
              .read(contactsFilterProvider.notifier)
              .updateFilter(ContactFilter(base: emptyBaseFilter));
          break;
        case EntityType.sshKey:
          ref
              .read(sshKeysFilterProvider.notifier)
              .updateFilter(SshKeyFilter(base: emptyBaseFilter));
          break;
        case EntityType.certificate:
          ref
              .read(certificatesFilterProvider.notifier)
              .updateFilter(CertificateFilter(base: emptyBaseFilter));
          break;
        case EntityType.cryptoWallet:
          ref
              .read(cryptoWalletsFilterProvider.notifier)
              .updateFilter(CryptoWalletFilter(base: emptyBaseFilter));
          break;
        case EntityType.wifi:
          ref
              .read(wifisFilterProvider.notifier)
              .updateFilter(WifiFilter(base: emptyBaseFilter));
          break;
        case EntityType.identity:
          ref
              .read(identitiesFilterProvider.notifier)
              .updateFilter(IdentityFilter(base: emptyBaseFilter));
          break;
        case EntityType.licenseKey:
          ref
              .read(licenseKeysFilterProvider.notifier)
              .updateFilter(LicenseKeyFilter(base: emptyBaseFilter));
          break;
        case EntityType.recoveryCodes:
          ref
              .read(recoveryCodesFilterProvider.notifier)
              .updateFilter(RecoveryCodesFilter(base: emptyBaseFilter));
          break;
        case EntityType.loyaltyCard:
          ref
              .read(loyaltyCardsFilterProvider.notifier)
              .updateFilter(LoyaltyCardFilter(base: emptyBaseFilter));
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

  final EntityType entityType;
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
  PasswordFilter? _localPasswordsFilter;
  NoteFilter? _localNotesFilter;
  OtpFilter? _localOtpsFilter;
  BankCardFilter? _localBankCardsFilter;
  FileFilter? _localFilesFilter;
  DocumentFilter? _localDocumentsFilter;
  ContactFilter? _localContactsFilter;
  ApiKeyFilter? _localApiKeysFilter;
  SshKeyFilter? _localSshKeysFilter;
  CertificateFilter? _localCertificatesFilter;
  CryptoWalletFilter? _localCryptoWalletsFilter;
  WifiFilter? _localWifisFilter;
  IdentityFilter? _localIdentitiesFilter;
  LicenseKeyFilter? _localLicenseKeysFilter;
  RecoveryCodesFilter? _localRecoveryCodesFilter;
  LoyaltyCardFilter? _localLoyaltyCardsFilter;

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
      case EntityType.password:
        _localPasswordsFilter = ref.read(passwordsFilterProvider);
        break;
      case EntityType.note:
        _localNotesFilter = ref.read(notesFilterProvider);
        break;
      case EntityType.otp:
        _localOtpsFilter = ref.read(otpsFilterProvider);
        break;
      case EntityType.bankCard:
        _localBankCardsFilter = ref.read(bankCardsFilterProvider);
        break;
      case EntityType.file:
        _localFilesFilter = ref.read(filesFilterProvider);
        break;

      case EntityType.document:
        _localDocumentsFilter = ref.read(documentsFilterProvider);
        break;
      case EntityType.apiKey:
        _localApiKeysFilter = ref.read(apiKeysFilterProvider);
        break;
      case EntityType.contact:
        _localContactsFilter = ref.read(contactsFilterProvider);
        break;
      case EntityType.sshKey:
        _localSshKeysFilter = ref.read(sshKeysFilterProvider);
        break;
      case EntityType.certificate:
        _localCertificatesFilter = ref.read(certificatesFilterProvider);
        break;
      case EntityType.cryptoWallet:
        _localCryptoWalletsFilter = ref.read(cryptoWalletsFilterProvider);
        break;
      case EntityType.wifi:
        _localWifisFilter = ref.read(wifisFilterProvider);
        break;
      case EntityType.identity:
        _localIdentitiesFilter = ref.read(identitiesFilterProvider);
        break;
      case EntityType.licenseKey:
        _localLicenseKeysFilter = ref.read(licenseKeysFilterProvider);
        break;
      case EntityType.recoveryCodes:
        _localRecoveryCodesFilter = ref.read(recoveryCodesFilterProvider);
        break;
      case EntityType.loyaltyCard:
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
      case EntityType.password:
        final passwordFilter = ref.read(passwordsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          passwordsFilter: passwordFilter,
        );
        break;

      case EntityType.document:
        final documentsFilter = ref.read(documentsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          documentsFilter: documentsFilter,
        );
        break;

      case EntityType.note:
        final notesFilter = ref.read(notesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          notesFilter: notesFilter,
        );
        break;

      case EntityType.otp:
        final otpFilter = ref.read(otpsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          otpsFilter: otpFilter,
        );
        break;

      case EntityType.bankCard:
        final bankCardsFilter = ref.read(bankCardsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          bankCardsFilter: bankCardsFilter,
        );
        break;

      case EntityType.file:
        final filesFilter = ref.read(filesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          filesFilter: filesFilter,
        );
        break;
      case EntityType.apiKey:
        final apiKeysFilter = ref.read(apiKeysFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          apiKeysFilter: apiKeysFilter,
        );
        break;
      case EntityType.contact:
        final contactsFilter = ref.read(contactsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          contactsFilter: contactsFilter,
        );
        break;
      case EntityType.sshKey:
        final sshKeysFilter = ref.read(sshKeysFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          sshKeysFilter: sshKeysFilter,
        );
        break;
      case EntityType.certificate:
        final certificatesFilter = ref.read(certificatesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          certificatesFilter: certificatesFilter,
        );
        break;
      case EntityType.cryptoWallet:
        final cryptoWalletsFilter = ref.read(cryptoWalletsFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          cryptoWalletsFilter: cryptoWalletsFilter,
        );
        break;
      case EntityType.wifi:
        final wifisFilter = ref.read(wifisFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          wifisFilter: wifisFilter,
        );
        break;
      case EntityType.identity:
        final identitiesFilter = ref.read(identitiesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          identitiesFilter: identitiesFilter,
        );
        break;
      case EntityType.licenseKey:
        final licenseKeysFilter = ref.read(licenseKeysFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          licenseKeysFilter: licenseKeysFilter,
        );
        break;
      case EntityType.recoveryCodes:
        final recoveryCodesFilter = ref.read(recoveryCodesFilterProvider);
        _initialValues = _InitialFilterValues(
          baseFilter: baseFilter,
          recoveryCodesFilter: recoveryCodesFilter,
        );
        break;
      case EntityType.loyaltyCard:
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

  Widget _buildCategoriesSection(EntityType entityType) {
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

  Widget _buildTagsSection(EntityType entityType) {
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

  Widget _buildBaseFiltersSection(EntityType entityType) {
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
                case EntityType.password:
                  if (_localPasswordsFilter != null) {
                    _localPasswordsFilter = _localPasswordsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.note:
                  if (_localNotesFilter != null) {
                    _localNotesFilter = _localNotesFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.otp:
                  if (_localOtpsFilter != null) {
                    _localOtpsFilter = _localOtpsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.bankCard:
                  if (_localBankCardsFilter != null) {
                    _localBankCardsFilter = _localBankCardsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.file:
                  if (_localFilesFilter != null) {
                    _localFilesFilter = _localFilesFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.document:
                  if (_localDocumentsFilter != null) {
                    _localDocumentsFilter = _localDocumentsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.apiKey:
                  if (_localApiKeysFilter != null) {
                    _localApiKeysFilter = _localApiKeysFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.contact:
                  if (_localContactsFilter != null) {
                    _localContactsFilter = _localContactsFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.sshKey:
                  if (_localSshKeysFilter != null) {
                    _localSshKeysFilter = _localSshKeysFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.certificate:
                  if (_localCertificatesFilter != null) {
                    _localCertificatesFilter = _localCertificatesFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
                case EntityType.cryptoWallet:
                  if (_localCryptoWalletsFilter != null) {
                    _localCryptoWalletsFilter = _localCryptoWalletsFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
                case EntityType.wifi:
                  if (_localWifisFilter != null) {
                    _localWifisFilter = _localWifisFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.identity:
                  if (_localIdentitiesFilter != null) {
                    _localIdentitiesFilter = _localIdentitiesFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.licenseKey:
                  if (_localLicenseKeysFilter != null) {
                    _localLicenseKeysFilter = _localLicenseKeysFilter!.copyWith(
                      base: updatedFilter,
                    );
                  }
                  break;
                case EntityType.recoveryCodes:
                  if (_localRecoveryCodesFilter != null) {
                    _localRecoveryCodesFilter = _localRecoveryCodesFilter!
                        .copyWith(base: updatedFilter);
                  }
                  break;
                case EntityType.loyaltyCard:
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

  Widget _buildSpecificFiltersSection(EntityType entityType) {
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

  Widget _buildEntitySpecificSection(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return PasswordFilterSection(
          filter:
              _localPasswordsFilter ?? PasswordFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localPasswordsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры паролей локально');
          },
        );

      case EntityType.note:
        return NotesFilterSection(
          filter: _localNotesFilter ?? NoteFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localNotesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры заметок локально');
          },
        );

      case EntityType.otp:
        return OtpsFilterSection(
          filter: _localOtpsFilter ?? OtpFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localOtpsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры OTP локально');
          },
        );

      case EntityType.bankCard:
        return BankCardsFilterSection(
          filter:
              _localBankCardsFilter ?? BankCardFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localBankCardsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры банковских карт локально');
          },
        );

      case EntityType.file:
        return FilesFilterSection(
          filter: _localFilesFilter ?? FileFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localFilesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры файлов локально');
          },
        );

      case EntityType.document:
        return DocumentsFilterSection(
          filter:
              _localDocumentsFilter ?? DocumentFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localDocumentsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры документов локально');
          },
        );
      case EntityType.apiKey:
        return ApiKeysFilterSection(
          filter: _localApiKeysFilter ?? ApiKeyFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localApiKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры API-ключей локально');
          },
        );
      case EntityType.contact:
        return ContactsFilterSection(
          filter: _localContactsFilter ?? ContactFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localContactsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры контактов локально');
          },
        );
      case EntityType.sshKey:
        return SshKeysFilterSection(
          filter: _localSshKeysFilter ?? SshKeyFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localSshKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры SSH-ключей локально');
          },
        );
      case EntityType.certificate:
        return CertificatesFilterSection(
          filter:
              _localCertificatesFilter ??
              CertificateFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localCertificatesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры сертификатов локально');
          },
        );
      case EntityType.cryptoWallet:
        return CryptoWalletsFilterSection(
          filter:
              _localCryptoWalletsFilter ??
              CryptoWalletFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localCryptoWalletsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры криптокошельков локально');
          },
        );
      case EntityType.wifi:
        return WifisFilterSection(
          filter: _localWifisFilter ?? WifiFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localWifisFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры Wi-Fi локально');
          },
        );
      case EntityType.identity:
        return IdentitiesFilterSection(
          filter:
              _localIdentitiesFilter ?? IdentityFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localIdentitiesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры идентификаций локально');
          },
        );
      case EntityType.licenseKey:
        return LicenseKeysFilterSection(
          filter:
              _localLicenseKeysFilter ??
              LicenseKeyFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localLicenseKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры лицензий локально');
          },
        );
      case EntityType.recoveryCodes:
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
      case EntityType.loyaltyCard:
        return LoyaltyCardsFilterSection(
          filter:
              _localLoyaltyCardsFilter ??
              LoyaltyCardFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localLoyaltyCardsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры карт лояльности локально');
          },
        );
    }
  }

  /// Загрузить имена категорий и тегов по их ID
  Future<void> _loadCategoryAndTagNames() async {
    if (!mounted) return;

    try {
      // Загружаем имена категорий через DAO
      if (_selectedCategoryIds.isNotEmpty) {
        final categoryDao = (await ref.read(vaultRepositories.future)).category;
        final categoryNames = <String>[];

        for (final id in _selectedCategoryIds) {
          final category = (await categoryDao.getCategory(id)).getOrThrow();
          if (category.isPresent) {
            categoryNames.add(category.getOrNull()!.name);
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
        final tagDao = (await ref.read(vaultRepositories.future)).tag;
        final tagNames = <String>[];

        for (final id in _selectedTagIds) {
          final tag = (await tagDao.getTag(id)).getOrThrow();
          if (tag.isPresent) {
            tagNames.add(tag.getOrNull()!.name);
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
        case EntityType.password:
          if (_localPasswordsFilter != null) {
            final syncedFilter = _localPasswordsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.note:
          if (_localNotesFilter != null) {
            final syncedFilter = _localNotesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(notesFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case EntityType.otp:
          if (_localOtpsFilter != null) {
            final syncedFilter = _localOtpsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(otpsFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case EntityType.bankCard:
          if (_localBankCardsFilter != null) {
            final syncedFilter = _localBankCardsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.file:
          if (_localFilesFilter != null) {
            final syncedFilter = _localFilesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(filesFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;

        case EntityType.document:
          if (_localDocumentsFilter != null) {
            final syncedFilter = _localDocumentsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(documentsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.apiKey:
          if (_localApiKeysFilter != null) {
            final syncedFilter = _localApiKeysFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(apiKeysFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case EntityType.contact:
          if (_localContactsFilter != null) {
            final syncedFilter = _localContactsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(contactsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.sshKey:
          if (_localSshKeysFilter != null) {
            final syncedFilter = _localSshKeysFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(sshKeysFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case EntityType.certificate:
          if (_localCertificatesFilter != null) {
            final syncedFilter = _localCertificatesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(certificatesFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.cryptoWallet:
          if (_localCryptoWalletsFilter != null) {
            final syncedFilter = _localCryptoWalletsFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(cryptoWalletsFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.wifi:
          if (_localWifisFilter != null) {
            final syncedFilter = _localWifisFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref.read(wifisFilterProvider.notifier).updateFilter(syncedFilter);
          }
          break;
        case EntityType.identity:
          if (_localIdentitiesFilter != null) {
            final syncedFilter = _localIdentitiesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(identitiesFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.licenseKey:
          if (_localLicenseKeysFilter != null) {
            final syncedFilter = _localLicenseKeysFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(licenseKeysFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.recoveryCodes:
          if (_localRecoveryCodesFilter != null) {
            final syncedFilter = _localRecoveryCodesFilter!.copyWith(
              base: _localBaseFilter,
            );
            ref
                .read(recoveryCodesFilterProvider.notifier)
                .updateFilter(syncedFilter);
          }
          break;
        case EntityType.loyaltyCard:
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
        case EntityType.password:
          if (_initialValues!.passwordsFilter != null) {
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilter(_initialValues!.passwordsFilter!);
          }
          break;
        case EntityType.note:
          if (_initialValues!.notesFilter != null) {
            ref
                .read(notesFilterProvider.notifier)
                .updateFilter(_initialValues!.notesFilter!);
          }
          break;
        case EntityType.otp:
          if (_initialValues!.otpsFilter != null) {
            ref
                .read(otpsFilterProvider.notifier)
                .updateFilter(_initialValues!.otpsFilter!);
          }
          break;
        case EntityType.bankCard:
          if (_initialValues!.bankCardsFilter != null) {
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilter(_initialValues!.bankCardsFilter!);
          }
          break;
        case EntityType.file:
          if (_initialValues!.filesFilter != null) {
            ref
                .read(filesFilterProvider.notifier)
                .updateFilter(_initialValues!.filesFilter!);
          }
          break;

        case EntityType.document:
          if (_initialValues!.documentsFilter != null) {
            ref
                .read(documentsFilterProvider.notifier)
                .updateFilter(_initialValues!.documentsFilter!);
          }
          break;
        case EntityType.apiKey:
          if (_initialValues!.apiKeysFilter != null) {
            ref
                .read(apiKeysFilterProvider.notifier)
                .updateFilter(_initialValues!.apiKeysFilter!);
          }
          break;
        case EntityType.contact:
          if (_initialValues!.contactsFilter != null) {
            ref
                .read(contactsFilterProvider.notifier)
                .updateFilter(_initialValues!.contactsFilter!);
          }
          break;
        case EntityType.sshKey:
          if (_initialValues!.sshKeysFilter != null) {
            ref
                .read(sshKeysFilterProvider.notifier)
                .updateFilter(_initialValues!.sshKeysFilter!);
          }
          break;
        case EntityType.certificate:
          if (_initialValues!.certificatesFilter != null) {
            ref
                .read(certificatesFilterProvider.notifier)
                .updateFilter(_initialValues!.certificatesFilter!);
          }
          break;
        case EntityType.cryptoWallet:
          if (_initialValues!.cryptoWalletsFilter != null) {
            ref
                .read(cryptoWalletsFilterProvider.notifier)
                .updateFilter(_initialValues!.cryptoWalletsFilter!);
          }
          break;
        case EntityType.wifi:
          if (_initialValues!.wifisFilter != null) {
            ref
                .read(wifisFilterProvider.notifier)
                .updateFilter(_initialValues!.wifisFilter!);
          }
          break;
        case EntityType.identity:
          if (_initialValues!.identitiesFilter != null) {
            ref
                .read(identitiesFilterProvider.notifier)
                .updateFilter(_initialValues!.identitiesFilter!);
          }
          break;
        case EntityType.licenseKey:
          if (_initialValues!.licenseKeysFilter != null) {
            ref
                .read(licenseKeysFilterProvider.notifier)
                .updateFilter(_initialValues!.licenseKeysFilter!);
          }
          break;
        case EntityType.recoveryCodes:
          if (_initialValues!.recoveryCodesFilter != null) {
            ref
                .read(recoveryCodesFilterProvider.notifier)
                .updateFilter(_initialValues!.recoveryCodesFilter!);
          }
          break;
        case EntityType.loyaltyCard:
          if (_initialValues!.loyaltyCardsFilter != null) {
            ref
                .read(loyaltyCardsFilterProvider.notifier)
                .updateFilter(_initialValues!.loyaltyCardsFilter!);
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
        case EntityType.password:
          _localPasswordsFilter = PasswordFilter(base: _localBaseFilter);
          break;
        case EntityType.note:
          _localNotesFilter = NoteFilter(base: _localBaseFilter);
          break;
        case EntityType.otp:
          _localOtpsFilter = OtpFilter(base: _localBaseFilter);
          break;
        case EntityType.bankCard:
          _localBankCardsFilter = BankCardFilter(base: _localBaseFilter);
          break;
        case EntityType.file:
          _localFilesFilter = FileFilter(base: _localBaseFilter);
          break;

        case EntityType.document:
          _localDocumentsFilter = DocumentFilter(base: _localBaseFilter);
          break;
        case EntityType.apiKey:
          _localApiKeysFilter = ApiKeyFilter(base: _localBaseFilter);
          break;
        case EntityType.contact:
          _localContactsFilter = ContactFilter(base: _localBaseFilter);
          break;
        case EntityType.sshKey:
          _localSshKeysFilter = SshKeyFilter(base: _localBaseFilter);
          break;
        case EntityType.certificate:
          _localCertificatesFilter = CertificateFilter(base: _localBaseFilter);
          break;
        case EntityType.cryptoWallet:
          _localCryptoWalletsFilter = CryptoWalletFilter(
            base: _localBaseFilter,
          );
          break;
        case EntityType.wifi:
          _localWifisFilter = WifiFilter(base: _localBaseFilter);
          break;
        case EntityType.identity:
          _localIdentitiesFilter = IdentityFilter(base: _localBaseFilter);
          break;
        case EntityType.licenseKey:
          _localLicenseKeysFilter = LicenseKeyFilter(base: _localBaseFilter);
          break;
        case EntityType.recoveryCodes:
          _localRecoveryCodesFilter = RecoveryCodesFilter(
            base: _localBaseFilter,
          );
          break;
        case EntityType.loyaltyCard:
          _localLoyaltyCardsFilter = LoyaltyCardFilter(base: _localBaseFilter);
          break;
      }
    });

    logInfo('FilterModal: Локальные поля фильтров очищены');
  }
}
