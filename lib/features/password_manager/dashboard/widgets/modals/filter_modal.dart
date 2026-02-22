import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/pickers/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

// Модели и провайдеры
import '../../models/entity_type.dart';
import '../../providers/filter_providers/api_keys_filter_provider.dart';
import '../../providers/filter_providers/bank_cards_filter_provider.dart';
import '../../providers/filter_providers/base_filter_provider.dart';
import '../../providers/filter_providers/documents_filter_provider.dart';
import '../../providers/filter_providers/files_filter_provider.dart';
import '../../providers/filter_providers/notes_filter_provider.dart';
import '../../providers/filter_providers/otp_filter_provider.dart';
import '../../providers/filter_providers/password_filter_provider.dart';
// Секции фильтров
import '../dashboard_home/filter_sections/filter_sections.dart';

/// Типобезопасное хранилище начальных значений фильтров
class _InitialFilterValues {
  final BaseFilter baseFilter;
  final PasswordsFilter? passwordsFilter;
  final NotesFilter? notesFilter;
  final OtpsFilter? otpsFilter;
  final BankCardsFilter? bankCardsFilter;
  final FilesFilter? filesFilter;
  final DocumentsFilter? documentsFilter;
  final ApiKeysFilter? apiKeysFilter;

  _InitialFilterValues({
    required this.baseFilter,
    this.passwordsFilter,
    this.notesFilter,
    this.otpsFilter,
    this.bankCardsFilter,
    this.filesFilter,
    this.documentsFilter,
    this.apiKeysFilter,
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
    // Получаем базовый фильтр для проверки активных ограничений
    final baseFilter = ref.watch(baseFilterProvider);
    final hasActiveFilters = baseFilter.hasActiveConstraints;

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
              .updateFilter(PasswordsFilter(base: emptyBaseFilter));
          break;
        case EntityType.note:
          ref
              .read(notesFilterProvider.notifier)
              .updateFilter(NotesFilter(base: emptyBaseFilter));
          break;
        case EntityType.otp:
          ref
              .read(otpsFilterProvider.notifier)
              .updateFilter(OtpsFilter(base: emptyBaseFilter));
          break;
        case EntityType.bankCard:
          ref
              .read(bankCardsFilterProvider.notifier)
              .updateFilter(BankCardsFilter(base: emptyBaseFilter));
          break;
        case EntityType.file:
          ref
              .read(filesFilterProvider.notifier)
              .updateFilter(FilesFilter(base: emptyBaseFilter));
          break;
        case EntityType.document:
          ref
              .read(documentsFilterProvider.notifier)
              .updateFilter(DocumentsFilter(base: emptyBaseFilter));
          break;
        case EntityType.apiKey:
          ref
              .read(apiKeysFilterProvider.notifier)
              .updateFilter(ApiKeysFilter(base: emptyBaseFilter));
          break;
        case EntityType.sshKey:
        case EntityType.certificate:
        case EntityType.cryptoWallet:
        case EntityType.wifi:
        case EntityType.identity:
        case EntityType.licenseKey:
        case EntityType.recoveryCodes:
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
  PasswordsFilter? _localPasswordsFilter;
  NotesFilter? _localNotesFilter;
  OtpsFilter? _localOtpsFilter;
  BankCardsFilter? _localBankCardsFilter;
  FilesFilter? _localFilesFilter;
  DocumentsFilter? _localDocumentsFilter;
  ApiKeysFilter? _localApiKeysFilter;

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
      case EntityType.sshKey:
      case EntityType.certificate:
      case EntityType.cryptoWallet:
      case EntityType.wifi:
      case EntityType.identity:
      case EntityType.licenseKey:
      case EntityType.recoveryCodes:
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
      case EntityType.sshKey:
      case EntityType.certificate:
      case EntityType.cryptoWallet:
      case EntityType.wifi:
      case EntityType.identity:
      case EntityType.licenseKey:
      case EntityType.recoveryCodes:
        _initialValues = _InitialFilterValues(baseFilter: baseFilter);
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
          filterByType: [_getCategoryType(entityType)],
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
          filterByType: [_getTagType(entityType)],
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
                case EntityType.sshKey:
                case EntityType.certificate:
                case EntityType.cryptoWallet:
                case EntityType.wifi:
                case EntityType.identity:
                case EntityType.licenseKey:
                case EntityType.recoveryCodes:
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
              _localPasswordsFilter ?? PasswordsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localPasswordsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры паролей локально');
          },
        );

      case EntityType.note:
        return NotesFilterSection(
          filter: _localNotesFilter ?? NotesFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localNotesFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры заметок локально');
          },
        );

      case EntityType.otp:
        return OtpsFilterSection(
          filter: _localOtpsFilter ?? OtpsFilter(base: _localBaseFilter),
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
              _localBankCardsFilter ?? BankCardsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localBankCardsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры банковских карт локально');
          },
        );

      case EntityType.file:
        return FilesFilterSection(
          filter: _localFilesFilter ?? FilesFilter(base: _localBaseFilter),
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
              _localDocumentsFilter ?? DocumentsFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localDocumentsFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры документов локально');
          },
        );
      case EntityType.apiKey:
        return ApiKeysFilterSection(
          filter: _localApiKeysFilter ?? ApiKeysFilter(base: _localBaseFilter),
          onFilterChanged: (updatedFilter) {
            setState(() {
              _localApiKeysFilter = updatedFilter;
            });
            logDebug('FilterModal: Обновлены фильтры API-ключей локально');
          },
        );
      case EntityType.sshKey:
      case EntityType.certificate:
      case EntityType.cryptoWallet:
      case EntityType.wifi:
      case EntityType.identity:
      case EntityType.licenseKey:
      case EntityType.recoveryCodes:
        return const Text('Специфичные фильтры для этого типа пока недоступны');
    }
  }

  CategoryType _getCategoryType(EntityType entityType) {
    switch (entityType) {
      case EntityType.document:
        return CategoryType.document;
      case EntityType.password:
        return CategoryType.password;
      case EntityType.note:
        return CategoryType.note;
      case EntityType.bankCard:
        return CategoryType.bankCard;
      case EntityType.file:
        return CategoryType.file;
      case EntityType.otp:
        return CategoryType.totp;
      case EntityType.apiKey:
        return CategoryType.apiKey;
      case EntityType.sshKey:
        return CategoryType.sshKey;
      case EntityType.certificate:
        return CategoryType.certificate;
      case EntityType.cryptoWallet:
        return CategoryType.cryptoWallet;
      case EntityType.wifi:
        return CategoryType.wifi;
      case EntityType.identity:
        return CategoryType.identity;
      case EntityType.licenseKey:
        return CategoryType.licenseKey;
      case EntityType.recoveryCodes:
        return CategoryType.recoveryCodes;
    }
  }

  TagType _getTagType(EntityType entityType) {
    switch (entityType) {
      case EntityType.document:
        return TagType.document;
      case EntityType.password:
        return TagType.password;
      case EntityType.note:
        return TagType.note;
      case EntityType.bankCard:
        return TagType.bankCard;
      case EntityType.file:
        return TagType.file;
      case EntityType.otp:
        return TagType.totp;
      case EntityType.apiKey:
        return TagType.apiKey;
      case EntityType.sshKey:
        return TagType.sshKey;
      case EntityType.certificate:
        return TagType.certificate;
      case EntityType.cryptoWallet:
        return TagType.cryptoWallet;
      case EntityType.wifi:
        return TagType.wifi;
      case EntityType.identity:
        return TagType.identity;
      case EntityType.licenseKey:
        return TagType.licenseKey;
      case EntityType.recoveryCodes:
        return TagType.recoveryCodes;
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
        case EntityType.sshKey:
        case EntityType.certificate:
        case EntityType.cryptoWallet:
        case EntityType.wifi:
        case EntityType.identity:
        case EntityType.licenseKey:
        case EntityType.recoveryCodes:
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
                .updateFilterDebounced(_initialValues!.passwordsFilter!);
          }
          break;
        case EntityType.note:
          if (_initialValues!.notesFilter != null) {
            ref
                .read(notesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.notesFilter!);
          }
          break;
        case EntityType.otp:
          if (_initialValues!.otpsFilter != null) {
            ref
                .read(otpsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.otpsFilter!);
          }
          break;
        case EntityType.bankCard:
          if (_initialValues!.bankCardsFilter != null) {
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.bankCardsFilter!);
          }
          break;
        case EntityType.file:
          if (_initialValues!.filesFilter != null) {
            ref
                .read(filesFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.filesFilter!);
          }
          break;

        case EntityType.document:
          if (_initialValues!.documentsFilter != null) {
            ref
                .read(documentsFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.documentsFilter!);
          }
          break;
        case EntityType.apiKey:
          if (_initialValues!.apiKeysFilter != null) {
            ref
                .read(apiKeysFilterProvider.notifier)
                .updateFilterDebounced(_initialValues!.apiKeysFilter!);
          }
          break;
        case EntityType.sshKey:
        case EntityType.certificate:
        case EntityType.cryptoWallet:
        case EntityType.wifi:
        case EntityType.identity:
        case EntityType.licenseKey:
        case EntityType.recoveryCodes:
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
          _localPasswordsFilter = PasswordsFilter(base: _localBaseFilter);
          break;
        case EntityType.note:
          _localNotesFilter = NotesFilter(base: _localBaseFilter);
          break;
        case EntityType.otp:
          _localOtpsFilter = OtpsFilter(base: _localBaseFilter);
          break;
        case EntityType.bankCard:
          _localBankCardsFilter = BankCardsFilter(base: _localBaseFilter);
          break;
        case EntityType.file:
          _localFilesFilter = FilesFilter(base: _localBaseFilter);
          break;

        case EntityType.document:
          _localDocumentsFilter = DocumentsFilter(base: _localBaseFilter);
          break;
        case EntityType.apiKey:
          _localApiKeysFilter = ApiKeysFilter(base: _localBaseFilter);
          break;
        case EntityType.sshKey:
        case EntityType.certificate:
        case EntityType.cryptoWallet:
        case EntityType.wifi:
        case EntityType.identity:
        case EntityType.licenseKey:
        case EntityType.recoveryCodes:
          break;
      }
    });

    logInfo('FilterModal: Локальные поля фильтров очищены');
  }
}
