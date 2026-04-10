import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/db_core/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class NotesFilterSection extends StatefulWidget {
  final NotesFilter filter;
  final Function(NotesFilter) onFilterChanged;

  const NotesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<NotesFilterSection> createState() => _NotesFilterSectionState();
}

class _NotesFilterSectionState extends State<NotesFilterSection> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _minContentLengthController;
  late TextEditingController _maxContentLengthController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.filter.title);
    _contentController = TextEditingController(text: widget.filter.content);
    _minContentLengthController = TextEditingController(
      text: widget.filter.minContentLength?.toString() ?? '',
    );
    _maxContentLengthController = TextEditingController(
      text: widget.filter.maxContentLength?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(NotesFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.title != widget.filter.title) {
      _titleController.text = widget.filter.title ?? '';
    }
    if (oldWidget.filter.content != widget.filter.content) {
      _contentController.text = widget.filter.content ?? '';
    }
    if (oldWidget.filter.minContentLength != widget.filter.minContentLength) {
      _minContentLengthController.text =
          widget.filter.minContentLength?.toString() ?? '';
    }
    if (oldWidget.filter.maxContentLength != widget.filter.maxContentLength) {
      _maxContentLengthController.text =
          widget.filter.maxContentLength?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _minContentLengthController.dispose();
    _maxContentLengthController.dispose();
    super.dispose();
  }

  void _updateFilter(NotesFilter Function(NotesFilter) updater) {
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
              Icon(Icons.note, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры заметок',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasNotesSpecificFilters())
                TextButton.icon(
                  onPressed: _clearNotesFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Текстовые фильтры
        _buildTextFilters(),

        const Divider(height: 1),

        // Статусные фильтры
        _buildStatusFilters(),

        const Divider(height: 1),

        // Длина контента
        _buildContentLengthSection(),

        const Divider(height: 1),

        // Пресеты
        _buildPresetsSection(),

        const Divider(height: 1),

        // Сортировка
        _buildSortingSection(),
      ],
    );
  }

  // ============================================================================
  // Текстовые фильтры
  // ============================================================================

  Widget _buildTextFilters() {
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

          // Заголовок
          TextField(
            controller: _titleController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Заголовок',
              hintText: 'Введите заголовок заметки...',
              prefixIcon: const Icon(Icons.title),
              suffixIcon: _titleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _titleController.clear();
                        _updateFilter((f) => f.copyWith(title: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(title: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Содержимое
          TextField(
            controller: _contentController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Содержимое',
              hintText: 'Введите текст для поиска в содержимом...',
              prefixIcon: const Icon(Icons.text_fields),
              suffixIcon: _contentController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _contentController.clear();
                        _updateFilter((f) => f.copyWith(content: null));
                      },
                    )
                  : null,
            ),
            maxLines: 3,
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(content: trimmed.isEmpty ? null : trimmed),
              );
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
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Наличие полей'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'С описанием',
                value: widget.filter.hasDescription,
                icon: Icons.description,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasDescription: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С форматированием (Delta JSON)',
                value: widget.filter.hasDeltaJson,
                icon: Icons.format_paint,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasDeltaJson: value));
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
    return widget.filter.hasDescription != null ||
        widget.filter.hasDeltaJson != null;
  }

  // ============================================================================
  // Длина контента
  // ============================================================================

  Widget _buildContentLengthSection() {
    return ExpansionTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('Длина содержимого'),
      initiallyExpanded:
          widget.filter.minContentLength != null ||
          widget.filter.maxContentLength != null,
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
                      controller: _minContentLengthController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Минимум символов',
                        prefixIcon: const Icon(Icons.arrow_upward),
                        errorText: !widget.filter.isValidContentLengthRange
                            ? 'Неверный диапазон'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        _updateFilter(
                          (f) => f.copyWith(minContentLength: intValue),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxContentLengthController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Максимум символов',
                        prefixIcon: const Icon(Icons.arrow_downward),
                        errorText: !widget.filter.isValidContentLengthRange
                            ? 'Неверный диапазон'
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        final intValue = int.tryParse(value);
                        _updateFilter(
                          (f) => f.copyWith(maxContentLength: intValue),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Быстрые пресеты длины
              const SizedBox(height: 12),
              Text(
                'Быстрый выбор',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLengthPresetChip(
                    label: 'Короткие (< 500)',
                    onTap: () {
                      _minContentLengthController.text = '';
                      _maxContentLengthController.text = '500';
                      _updateFilter(
                        (f) => f.copyWith(
                          minContentLength: null,
                          maxContentLength: 500,
                        ),
                      );
                    },
                  ),
                  _buildLengthPresetChip(
                    label: 'Средние (500-5000)',
                    onTap: () {
                      _minContentLengthController.text = '500';
                      _maxContentLengthController.text = '5000';
                      _updateFilter(
                        (f) => f.copyWith(
                          minContentLength: 500,
                          maxContentLength: 5000,
                        ),
                      );
                    },
                  ),
                  _buildLengthPresetChip(
                    label: 'Длинные (> 5000)',
                    onTap: () {
                      _minContentLengthController.text = '5000';
                      _maxContentLengthController.text = '';
                      _updateFilter(
                        (f) => f.copyWith(
                          minContentLength: 5000,
                          maxContentLength: null,
                        ),
                      );
                    },
                  ),
                  _buildLengthPresetChip(
                    label: 'Пустые (= 0)',
                    onTap: () {
                      _minContentLengthController.text = '0';
                      _maxContentLengthController.text = '0';
                      _updateFilter(
                        (f) => f.copyWith(
                          minContentLength: 0,
                          maxContentLength: 0,
                        ),
                      );
                    },
                  ),
                ],
              ),

              if (widget.filter.minContentLength != null ||
                  widget.filter.maxContentLength != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _minContentLengthController.clear();
                      _maxContentLengthController.clear();
                      _updateFilter(
                        (f) => f.copyWith(
                          minContentLength: null,
                          maxContentLength: null,
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Сбросить длину'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLengthPresetChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.filter_alt, size: 18),
    );
  }

  // ============================================================================
  // Пресеты
  // ============================================================================

  Widget _buildPresetsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрые пресеты',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Пустые заметки'),
                avatar: const Icon(Icons.note_outlined, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(minContentLength: 0, maxContentLength: 0),
                  );
                },
              ),
              ActionChip(
                label: const Text('С форматированием'),
                avatar: const Icon(Icons.format_paint, size: 18),
                onPressed: () {
                  _updateFilter((f) => f.copyWith(hasDeltaJson: true));
                },
              ),
              ActionChip(
                label: const Text('Простой текст'),
                avatar: const Icon(Icons.text_fields, size: 18),
                onPressed: () {
                  _updateFilter((f) => f.copyWith(hasDeltaJson: false));
                },
              ),
              ActionChip(
                label: const Text('С описанием'),
                avatar: const Icon(Icons.description, size: 18),
                onPressed: () {
                  _updateFilter((f) => f.copyWith(hasDescription: true));
                },
              ),
              ActionChip(
                label: const Text('Детальные заметки'),
                avatar: const Icon(Icons.article, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) =>
                        f.copyWith(hasDescription: true, minContentLength: 100),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Сортировка
  // ============================================================================

  Widget _buildSortingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сортировка',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip(
                label: 'По заголовку',
                field: NotesSortField.title,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По описанию',
                field: NotesSortField.description,
                icon: Icons.description,
              ),
              _buildSortChip(
                label: 'По длине',
                field: NotesSortField.contentLength,
                icon: Icons.text_fields,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: NotesSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: NotesSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: NotesSortField.lastAccessed,
                icon: Icons.access_time,
              ),
            ],
          ),
          if (widget.filter.sortField != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _updateFilter((f) => f.copyWith(sortField: null));
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Сбросить сортировку'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required NotesSortField field,
    required IconData icon,
  }) {
    final isSelected = widget.filter.sortField == field;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? colorScheme.onSecondaryContainer : null,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(sortField: selected ? field : null));
      },
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
    );
  }

  // ============================================================================
  // Вспомогательные методы
  // ============================================================================

  bool _hasNotesSpecificFilters() {
    return widget.filter.title != null ||
        widget.filter.content != null ||
        widget.filter.hasDescription != null ||
        widget.filter.hasDeltaJson != null ||
        widget.filter.minContentLength != null ||
        widget.filter.maxContentLength != null ||
        widget.filter.sortField != null;
  }

  void _clearNotesFilters() {
    _titleController.clear();
    _contentController.clear();
    _minContentLengthController.clear();
    _maxContentLengthController.clear();

    _updateFilter(
      (f) => f.copyWith(
        title: null,
        content: null,
        hasDescription: null,
        hasDeltaJson: null,
        minContentLength: null,
        maxContentLength: null,
        sortField: null,
      ),
    );
  }
}
