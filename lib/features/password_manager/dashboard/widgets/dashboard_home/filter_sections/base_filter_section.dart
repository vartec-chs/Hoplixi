import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:intl/intl.dart';

class BaseFilterSection extends StatefulWidget {
  final BaseFilter filter;
  final Function(BaseFilter) onFilterChanged;
  final String entityTypeName; // Название типа сущности для UI

  const BaseFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.entityTypeName,
  });

  @override
  State<BaseFilterSection> createState() => _BaseFilterSectionState();
}

class _BaseFilterSectionState extends State<BaseFilterSection> {
  late TextEditingController _queryController;
  late TextEditingController _minUsedCountController;
  late TextEditingController _maxUsedCountController;
  late TextEditingController _frequencyWindowDaysController;

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.filter.query);
    _minUsedCountController = TextEditingController(
      text: widget.filter.minUsedCount?.toString() ?? '',
    );
    _maxUsedCountController = TextEditingController(
      text: widget.filter.maxUsedCount?.toString() ?? '',
    );
    _frequencyWindowDaysController = TextEditingController(
      text: widget.filter.frequencyWindowDays?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(BaseFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.query != widget.filter.query) {
      _queryController.text = widget.filter.query;
    }
    if (oldWidget.filter.minUsedCount != widget.filter.minUsedCount) {
      _minUsedCountController.text =
          widget.filter.minUsedCount?.toString() ?? '';
    }
    if (oldWidget.filter.maxUsedCount != widget.filter.maxUsedCount) {
      _maxUsedCountController.text =
          widget.filter.maxUsedCount?.toString() ?? '';
    }
    if (oldWidget.filter.frequencyWindowDays !=
        widget.filter.frequencyWindowDays) {
      _frequencyWindowDaysController.text =
          widget.filter.frequencyWindowDays?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _minUsedCountController.dispose();
    _maxUsedCountController.dispose();
    _frequencyWindowDaysController.dispose();
    super.dispose();
  }

  void _updateFilter(BaseFilter Function(BaseFilter) updater) {
    widget.onFilterChanged(updater(widget.filter));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Базовые фильтры',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.filter.hasActiveConstraints)
                TextButton.icon(
                  onPressed: () => _updateFilter((f) => const BaseFilter()),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Поиск по тексту
        _buildSearchSection(),

        const Divider(height: 1),

        // Статусные фильтры
        _buildStatusFilters(),

        const Divider(height: 1),

        // Фильтры по датам
        _buildDateFilters(),

        const Divider(height: 1),

        // Фильтр по количеству использований
        _buildUsageCountFilters(),

        const Divider(height: 1),

        // Тип сортировки
        _buildSortByFilter(),

        const Divider(height: 1),

        // Направление сортировки
        _buildSortDirectionFilter(),
      ],
    );
  }

  // ============================================================================
  // Секция поиска
  // ============================================================================

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поиск',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _queryController,
            decoration: primaryInputDecoration(
              context,
              hintText: 'Поиск по ${widget.entityTypeName.toLowerCase()}...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _queryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _queryController.clear();
                        _updateFilter((f) => f.copyWith(query: ''));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _updateFilter((f) => f.copyWith(query: value.trim()));
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.toggle_on),
      title: const Text('Статус'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Избранное',
                value: widget.filter.isFavorite,
                icon: Icons.star,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(isFavorite: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Архивированное',
                value: widget.filter.isArchived,
                icon: Icons.archive,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(isArchived: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Удаленное',
                value: widget.filter.isDeleted,
                icon: Icons.delete,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(isDeleted: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Закрепленное',
                value: widget.filter.isPinned,
                icon: Icons.push_pin,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(isPinned: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С заметками',
                value: widget.filter.hasNotes,
                icon: Icons.note,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasNotes: value));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTriStateCheckbox({
    required String label,
    required bool? value,
    required IconData icon,
    required void Function(bool?) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // Cycle: null -> true -> false -> null
        if (value == null) {
          onChanged(true);
        } else if (value == true) {
          onChanged(false);
        } else {
          onChanged(null);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: value == true
              ? colorScheme.primary.withOpacity(0.1)
              : value == false
              ? colorScheme.error.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value == true
                  ? colorScheme.primary
                  : value == false
                  ? colorScheme.error
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (value != null)
              Icon(
                value ? Icons.check : Icons.close,
                size: 18,
                color: value ? colorScheme.primary : colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveStatusFilters() {
    return widget.filter.isFavorite != null ||
        widget.filter.isArchived != null ||
        widget.filter.isDeleted != null ||
        widget.filter.isPinned != null ||
        widget.filter.hasNotes != null;
  }

  // ============================================================================
  // Фильтры по датам
  // ============================================================================

  Widget _buildDateFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.calendar_today),
      title: const Text('Даты'),
      initiallyExpanded: _hasActiveDateFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Дата создания
              Text(
                'Дата создания',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'С',
                      date: widget.filter.createdAfter,
                      onChanged: (date) {
                        _updateFilter((f) => f.copyWith(createdAfter: date));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateField(
                      label: 'По',
                      date: widget.filter.createdBefore,
                      onChanged: (date) {
                        _updateFilter((f) => f.copyWith(createdBefore: date));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Дата изменения
              Text(
                'Дата изменения',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'С',
                      date: widget.filter.modifiedAfter,
                      onChanged: (date) {
                        _updateFilter((f) => f.copyWith(modifiedAfter: date));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateField(
                      label: 'По',
                      date: widget.filter.modifiedBefore,
                      onChanged: (date) {
                        _updateFilter((f) => f.copyWith(modifiedBefore: date));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Дата последнего доступа
              Text(
                'Дата последнего использования',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'С',
                      date: widget.filter.lastUsedAfter,
                      onChanged: (date) {
                        _updateFilter((f) => f.copyWith(lastUsedAfter: date));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateField(
                      label: 'По',
                      date: widget.filter.lastUsedBefore,
                      onChanged: (date) {
                        _updateFilter((f) => f.copyWith(lastUsedBefore: date));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required void Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () => _selectDate(date, onChanged),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: primaryInputDecoration(
          context,
          labelText: label,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null ? _dateFormat.format(date) : 'Не выбрано',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: date != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
    DateTime? currentDate,
    void Function(DateTime?) onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  bool _hasActiveDateFilters() {
    return widget.filter.createdAfter != null ||
        widget.filter.createdBefore != null ||
        widget.filter.modifiedAfter != null ||
        widget.filter.modifiedBefore != null ||
        widget.filter.lastUsedAfter != null ||
        widget.filter.lastUsedBefore != null;
  }

  // ============================================================================
  // Фильтр по количеству использований
  // ============================================================================

  Widget _buildUsageCountFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.bar_chart),
      title: const Text('Количество использований'),
      initiallyExpanded: _hasActiveUsageCountFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minUsedCountController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Минимум',
                        prefixIcon: const Icon(Icons.arrow_upward),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        _updateFilter(
                          (f) => f.copyWith(minUsedCount: intValue),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxUsedCountController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Максимум',
                        prefixIcon: const Icon(Icons.arrow_downward),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        _updateFilter(
                          (f) => f.copyWith(maxUsedCount: intValue),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Окно активности (дней)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _frequencyWindowDaysController,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Количество дней',
                  hintText: '7',
                  prefixIcon: const Icon(Icons.calendar_view_week),
                  helperText: 'Для сортировки по активности (по умолчанию 7)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  _updateFilter(
                    (f) => f.copyWith(frequencyWindowDays: intValue),
                  );
                },
              ),
            ],
          ),
        ),
        if (widget.filter.minUsedCount != null ||
            widget.filter.maxUsedCount != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _minUsedCountController.clear();
                  _maxUsedCountController.clear();
                  _updateFilter(
                    (f) => f.copyWith(minUsedCount: null, maxUsedCount: null),
                  );
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Очистить'),
              ),
            ),
          ),
      ],
    );
  }

  bool _hasActiveUsageCountFilters() {
    return widget.filter.minUsedCount != null ||
        widget.filter.maxUsedCount != null ||
        widget.filter.frequencyWindowDays != null;
  }

  // ============================================================================
  // Тип сортировки
  // ============================================================================

  Widget _buildSortByFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип сортировки',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: SortBy.values.map((sortBy) {
              final isSelected = widget.filter.sortBy == sortBy;
              return ChoiceChip(
                label: Text(_getSortByLabel(sortBy)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _updateFilter((f) => f.copyWith(sortBy: sortBy));
                  }
                },
                avatar: Icon(_getSortByIcon(sortBy), size: 18),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSortByLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.createdAt:
        return 'Дата создания';
      case SortBy.modifiedAt:
        return 'Дата изменения';
      case SortBy.lastUsedAt:
        return 'Последнее использование';
      case SortBy.recentScore:
        return 'По активности';
    }
  }

  IconData _getSortByIcon(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.createdAt:
        return Icons.add_circle_outline;
      case SortBy.modifiedAt:
        return Icons.edit;
      case SortBy.lastUsedAt:
        return Icons.access_time;
      case SortBy.recentScore:
        return Icons.trending_up;
    }
  }

  // ============================================================================
  // Направление сортировки
  // ============================================================================

  Widget _buildSortDirectionFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Направление сортировки',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SegmentedButton<SortDirection>(
            segments: const [
              ButtonSegment(
                value: SortDirection.asc,
                label: Text('По возрастанию'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: SortDirection.desc,
                label: Text('По убыванию'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {widget.filter.sortDirection},
            onSelectionChanged: (Set<SortDirection> selected) {
              _updateFilter((f) => f.copyWith(sortDirection: selected.first));
            },
          ),
        ],
      ),
    );
  }
}
