import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/managers/category_manager/providers/category_filter_provider.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/categories_filter.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class CategoryManagerFilterBar extends ConsumerStatefulWidget {
  const CategoryManagerFilterBar({super.key});

  @override
  ConsumerState<CategoryManagerFilterBar> createState() =>
      _CategoryManagerFilterBarState();
}

class _CategoryManagerFilterBarState
    extends ConsumerState<CategoryManagerFilterBar> {
  late final TextEditingController _controller;
  late final ProviderSubscription<CategoriesFilter> _filterSubscription;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(categoryFilterProvider).query;
    _controller = TextEditingController(text: initialQuery);
    _filterSubscription = ref.listenManual(categoryFilterProvider, (
      previous,
      next,
    ) {
      if (_controller.text == next.query) {
        return;
      }

      _controller.value = TextEditingValue(
        text: next.query,
        selection: TextSelection.collapsed(offset: next.query.length),
      );
    });
  }

  @override
  void dispose() {
    _filterSubscription.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(categoryFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: primaryInputDecoration(
                      context,
                      hintText: 'Поиск категорий...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Очистить поиск',
                              onPressed: () {
                                _controller.clear();
                                ref
                                    .read(categoryFilterProvider.notifier)
                                    .updateQuery('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      ref
                          .read(categoryFilterProvider.notifier)
                          .updateQuery(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Фильтры',
                  onPressed: () => _showFiltersSheet(context, filter),
                  icon: Badge(
                    isLabelVisible: _activeFilterCount(filter) > 0,
                    label: Text('${_activeFilterCount(filter)}'),
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: !_hasVisibleFilterChips(filter)
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type
                              in filter.types.whereType<CategoryType>())
                            InputChip(
                              label: Text(_typeLabel(type)),
                              onDeleted: () {
                                final nextTypes = filter.types
                                    .whereType<CategoryType>()
                                    .where((item) => item != type)
                                    .cast<CategoryType?>()
                                    .toList(growable: false);
                                ref
                                    .read(categoryFilterProvider.notifier)
                                    .updateFilter(
                                      filter.copyWith(types: nextTypes),
                                    );
                              },
                            ),
                          if (filter.hasIcon != null)
                            InputChip(
                              label: Text(
                                filter.hasIcon! ? 'С иконкой' : 'Без иконки',
                              ),
                              onDeleted: () {
                                ref
                                    .read(categoryFilterProvider.notifier)
                                    .updateFilter(
                                      filter.copyWith(hasIcon: null),
                                    );
                              },
                            ),
                          if (filter.hasDescription != null)
                            InputChip(
                              label: Text(
                                filter.hasDescription!
                                    ? 'С описанием'
                                    : 'Без описания',
                              ),
                              onDeleted: () {
                                ref
                                    .read(categoryFilterProvider.notifier)
                                    .updateFilter(
                                      filter.copyWith(hasDescription: null),
                                    );
                              },
                            ),
                          ActionChip(
                            avatar: Icon(
                              Icons.restart_alt_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            label: const Text('Сбросить'),
                            onPressed: () {
                              _controller.clear();
                              ref.read(categoryFilterProvider.notifier).reset();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int _activeFilterCount(CategoriesFilter filter) {
    var count = 0;
    count += filter.types.whereType<CategoryType>().length;
    if (filter.hasIcon != null) {
      count++;
    }
    if (filter.hasDescription != null) {
      count++;
    }
    return count;
  }

  bool _hasVisibleFilterChips(CategoriesFilter filter) {
    return filter.types.whereType<CategoryType>().isNotEmpty ||
        filter.hasIcon != null ||
        filter.hasDescription != null;
  }

  Future<void> _showFiltersSheet(
    BuildContext context,
    CategoriesFilter filter,
  ) async {
    final selectedTypes = filter.types.whereType<CategoryType>().toSet();
    var hasIcon = filter.hasIcon;
    var hasDescription = filter.hasDescription;

    await WoltModalSheet.show<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      useSafeArea: true,
      pageListBuilder: (modalSheetContext) => [
        WoltModalSheetPage(
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          surfaceTintColor: Colors.transparent,
          topBarTitle: Text(
            'Фильтрация категорий',
            style: Theme.of(modalSheetContext).textTheme.titleMedium,
          ),
          leadingNavBarWidget: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(modalSheetContext).pop(),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Типы',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type in CategoryType.values)
                            FilterChip(
                              label: Text(_typeLabel(type)),
                              selected: selectedTypes.contains(type),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedTypes.add(type);
                                  } else {
                                    selectedTypes.remove(type);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Иконка',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Любые'),
                            selected: hasIcon == null,
                            onSelected: (_) =>
                                setModalState(() => hasIcon = null),
                          ),
                          ChoiceChip(
                            label: const Text('Только с иконкой'),
                            selected: hasIcon == true,
                            onSelected: (_) =>
                                setModalState(() => hasIcon = true),
                          ),
                          ChoiceChip(
                            label: const Text('Только без иконки'),
                            selected: hasIcon == false,
                            onSelected: (_) =>
                                setModalState(() => hasIcon = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Описание',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Любые'),
                            selected: hasDescription == null,
                            onSelected: (_) =>
                                setModalState(() => hasDescription = null),
                          ),
                          ChoiceChip(
                            label: const Text('Только с описанием'),
                            selected: hasDescription == true,
                            onSelected: (_) =>
                                setModalState(() => hasDescription = true),
                          ),
                          ChoiceChip(
                            label: const Text('Только без описания'),
                            selected: hasDescription == false,
                            onSelected: (_) =>
                                setModalState(() => hasDescription = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SmoothButton(
                              onPressed: () {
                                selectedTypes.clear();
                                hasIcon = null;
                                hasDescription = null;
                                setModalState(() {});
                              },
                              label: 'Сбросить',
                              type: SmoothButtonType.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SmoothButton(
                              onPressed: () {
                                ref
                                    .read(categoryFilterProvider.notifier)
                                    .updateFilter(
                                      filter.copyWith(
                                        types: selectedTypes
                                            .cast<CategoryType?>()
                                            .toList(growable: false),
                                        hasIcon: hasIcon,
                                        hasDescription: hasDescription,
                                      ),
                                    );
                                Navigator.of(modalSheetContext).pop();
                              },
                              label: 'Применить',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _typeLabel(CategoryType type) {
  return switch (type) {
    CategoryType.note => 'Заметки',
    CategoryType.password => 'Пароли',
    CategoryType.totp => 'TOTP',
    CategoryType.bankCard => 'Банковские карты',
    CategoryType.file => 'Файлы',
    CategoryType.document => 'Документы',
    CategoryType.contact => 'Контакты',
    CategoryType.apiKey => 'API ключи',
    CategoryType.sshKey => 'SSH ключи',
    CategoryType.certificate => 'Сертификаты',
    CategoryType.cryptoWallet => 'Криптокошельки',
    CategoryType.wifi => 'Wi‑Fi',
    CategoryType.identity => 'Профили',
    CategoryType.licenseKey => 'Лицензионные ключи',
    CategoryType.recoveryCodes => 'Коды восстановления',
    CategoryType.loyaltyCard => 'Карты лояльности',
    CategoryType.mixed => 'Смешанные',
  };
}
