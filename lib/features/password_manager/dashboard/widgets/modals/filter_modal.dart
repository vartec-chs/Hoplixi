import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

// Модели и провайдеры
import '../../models/entity_type.dart';
import '../../providers/filter_providers/bank_cards_filter_provider.dart';
import '../../providers/filter_providers/base_filter_provider.dart';
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

  _InitialFilterValues({
    required this.baseFilter,
    this.passwordsFilter,
    this.notesFilter,
    this.otpsFilter,
    this.bankCardsFilter,
    this.filesFilter,
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
      onModalDismissedWithBarrierTap: () {
        logDebug('FilterModal: Закрытие по тапу на барьер');
        // Просто закрываем без применения изменений
      },
    );
  }

  /// Построить главную страницу фильтра
  static WoltModalSheetPage _buildMainFilterPage(
    BuildContext context,
    EntityType entityType,
    VoidCallback? onFilterApplied,
  ) {
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
        padding: EdgeInsets.only(left: 8.0),
        child: ModalSheetCloseButton(),
      ),

      child: _FilterModalContent(
        entityType: entityType,
        onFilterApplied: onFilterApplied,
      ),
    );
  }
}

/// Основное содержимое модального окна фильтра
class _FilterModalContent extends ConsumerStatefulWidget {
  const _FilterModalContent({required this.entityType, this.onFilterApplied});

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
    }
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
        minHeight: UniversalPlatform.isDesktop ? windowHeight * 0.88 : 0,
        maxHeight: UniversalPlatform.isDesktop
            ? windowHeight * 0.88
            : double.infinity,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Прокручиваемый контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // Закрепленные кнопки внизу
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: _buildActionButtons(context),
          ),
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
          filterByType: _getCategoryType(entityType),
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
          filterByType: _getTagType(entityType),
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
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasActiveFilters = _localBaseFilter.hasActiveConstraints;

    return Row(
      children: [
        // Кнопка сброса
        if (hasActiveFilters)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Сбросить'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (hasActiveFilters) const SizedBox(width: 12),

        // Кнопка применения
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _applyFilters(context),
            icon: const Icon(Icons.check),
            label: const Text('Применить'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  CategoryType _getCategoryType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return CategoryType.password;
      case EntityType.note:
        return CategoryType.notes;
      case EntityType.bankCard:
        return CategoryType.bankCard;
      case EntityType.file:
        return CategoryType.files;
      case EntityType.otp:
        return CategoryType.totp;
    }
  }

  TagType _getTagType(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return TagType.password;
      case EntityType.note:
        return TagType.notes;
      case EntityType.bankCard:
        return TagType.bankCard;
      case EntityType.file:
        return TagType.files;
      case EntityType.otp:
        return TagType.totp;
    }
  }

  void _resetFilters() {
    logDebug('FilterModal: Сброс всех локальных фильтров');

    try {
      final entityType = widget.entityType;
      final emptyBaseFilter = const BaseFilter();

      // Сброс локальных фильтров
      setState(() {
        _localBaseFilter = emptyBaseFilter;
        _selectedCategoryIds = [];
        _selectedCategoryNames = [];
        _selectedTagIds = [];
        _selectedTagNames = [];

        // Сброс специфичных фильтров
        switch (entityType) {
          case EntityType.password:
            _localPasswordsFilter = PasswordsFilter(base: emptyBaseFilter);
            break;
          case EntityType.note:
            _localNotesFilter = NotesFilter(base: emptyBaseFilter);
            break;
          case EntityType.otp:
            _localOtpsFilter = OtpsFilter(base: emptyBaseFilter);
            break;
          case EntityType.bankCard:
            _localBankCardsFilter = BankCardsFilter(base: emptyBaseFilter);
            break;
          case EntityType.file:
            _localFilesFilter = FilesFilter(base: emptyBaseFilter);
            break;
        }
      });

      logInfo('FilterModal: Локальные фильтры сброшены');
    } catch (e) {
      logError('FilterModal: Ошибка при сбросе фильтров', error: e);
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

  void _applyFilters(BuildContext context) {
    logDebug('FilterModal: Применение локальных фильтров к провайдерам');

    try {
      final entityType = widget.entityType;

      // Применяем базовый фильтр через отдельные setter'ы для каждого поля
      final baseNotifier = ref.read(baseFilterProvider.notifier);
      baseNotifier.updateFilter(_localBaseFilter);

      // Применяем специфичный для типа фильтр
      switch (entityType) {
        case EntityType.password:
          if (_localPasswordsFilter != null) {
            ref
                .read(passwordsFilterProvider.notifier)
                .updateFilter(_localPasswordsFilter!);
          }
          break;
        case EntityType.note:
          if (_localNotesFilter != null) {
            ref
                .read(notesFilterProvider.notifier)
                .updateFilter(_localNotesFilter!);
          }
          break;
        case EntityType.otp:
          if (_localOtpsFilter != null) {
            ref
                .read(otpsFilterProvider.notifier)
                .updateFilter(_localOtpsFilter!);
          }
          break;
        case EntityType.bankCard:
          if (_localBankCardsFilter != null) {
            ref
                .read(bankCardsFilterProvider.notifier)
                .updateFilter(_localBankCardsFilter!);
          }
          break;
        case EntityType.file:
          if (_localFilesFilter != null) {
            ref
                .read(filesFilterProvider.notifier)
                .updateFilter(_localFilesFilter!);
          }
          break;
      }

      widget.onFilterApplied?.call();
      Navigator.of(context).pop();
      logInfo('FilterModal: Фильтры успешно применены');
    } catch (e) {
      logError('FilterModal: Ошибка при применении фильтров', error: e);
    }
  }
}
