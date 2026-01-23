import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:hoplixi/main_store/models/filter/icons_filter.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import '../provider/icon_filter_provider.dart';

/// SliverAppBar для экрана управления иконками
class IconManagerAppBar extends ConsumerStatefulWidget {
  const IconManagerAppBar({super.key});

  @override
  ConsumerState<IconManagerAppBar> createState() => _IconManagerAppBarState();
}

class _IconManagerAppBarState extends ConsumerState<IconManagerAppBar> {
  late final TextEditingController _searchController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      title: _isSearchActive
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: primaryInputDecoration(
                context,
                hintText: 'Поиск иконок...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(iconFilterProvider.notifier).updateQuery('');
                  },
                ),
              ),
              onChanged: (value) {
                // Используем встроенный дебаунсинг в updateQuery
                ref.read(iconFilterProvider.notifier).updateQuery(value);
              },
            )
          : const Text('Иконки'),
      actions: [
        if (!_isSearchActive)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = true;
              });
            },
            tooltip: 'Поиск',
          )
        else
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearchActive = false;
                _searchController.clear();
                ref.read(iconFilterProvider.notifier).updateQuery('');
              });
            },
            tooltip: 'Закрыть поиск',
          ),
        Consumer(
          builder: (context, ref, child) {
            final currentSortField = ref.watch(
              iconFilterProvider.select((filter) => filter.sortField),
            );

            return PopupMenuButton<IconsSortField>(
              icon: const Icon(Icons.sort),
              tooltip: 'Сортировка',
              onSelected: (sortField) async {
                // Избегаем ненужного обновления если значение не изменилось
                if (sortField != currentSortField) {
                  await ref
                      .read(iconFilterProvider.notifier)
                      .updateSortField(sortField);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: IconsSortField.name,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.name)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.name)
                        const SizedBox(width: 8),
                      const Text('По названию'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IconsSortField.type,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.type)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.type)
                        const SizedBox(width: 8),
                      const Text('По типу'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IconsSortField.createdAt,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.createdAt)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.createdAt)
                        const SizedBox(width: 8),
                      const Text('По дате создания'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: IconsSortField.modifiedAt,
                  child: Row(
                    children: [
                      if (currentSortField == IconsSortField.modifiedAt)
                        const Icon(Icons.check, size: 20),
                      if (currentSortField == IconsSortField.modifiedAt)
                        const SizedBox(width: 8),
                      const Text('По дате изменения'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            _showFilterDialog(context);
          },
          tooltip: 'Фильтры',
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    final filter = ref.read(iconFilterProvider);

    // Локальное состояние для диалога
    String? typeFilter = filter.type;
    DateTime? createdAfter = filter.createdAfter;
    DateTime? createdBefore = filter.createdBefore;

    WoltModalSheet.show(
      context: context,
      barrierDismissible: true,
      pageListBuilder: (modalContext) {
        return [
          WoltModalSheetPage(
            surfaceTintColor: Colors.transparent,
            hasTopBarLayer: true,
            topBarTitle: Text(
              'Фильтры',
              style: Theme.of(modalContext).textTheme.titleMedium,
            ),
            isTopBarLayerAlwaysVisible: true,
            leadingNavBarWidget: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
            child: StatefulBuilder(
              builder: (context, setState) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фильтр по типу
                    TextField(
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Тип иконки',
                        hintText: 'Например: svg, png',
                      ),
                      controller: TextEditingController(text: typeFilter ?? ''),
                      onChanged: (value) {
                        setState(() {
                          typeFilter = value.isEmpty ? null : value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Фильтр по дате создания (от)
                    TextField(
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Создана после',
                        hintText: 'Выберите дату',
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: createdAfter ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            createdAfter = date;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: createdAfter != null
                            ? '${createdAfter!.day}.${createdAfter!.month}.${createdAfter!.year}'
                            : '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Фильтр по дате создания (до)
                    TextField(
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Создана до',
                        hintText: 'Выберите дату',
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: createdBefore ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            createdBefore = date;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: createdBefore != null
                            ? '${createdBefore!.day}.${createdBefore!.month}.${createdBefore!.year}'
                            : '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Кнопки действий
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await ref.read(iconFilterProvider.notifier).reset();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Сбросить'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            // Применяем фильтры
                            if (typeFilter != null &&
                                typeFilter!.trim().isNotEmpty) {
                              await ref
                                  .read(iconFilterProvider.notifier)
                                  .updateType(typeFilter);
                            } else if (typeFilter != filter.type) {
                              await ref
                                  .read(iconFilterProvider.notifier)
                                  .updateType(null);
                            }

                            if (createdAfter != filter.createdAfter) {
                              await ref
                                  .read(iconFilterProvider.notifier)
                                  .updateCreatedAfter(createdAfter);
                            }

                            if (createdBefore != filter.createdBefore) {
                              await ref
                                  .read(iconFilterProvider.notifier)
                                  .updateCreatedBefore(createdBefore);
                            }

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Применить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}
