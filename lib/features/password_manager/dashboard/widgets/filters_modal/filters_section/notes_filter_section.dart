import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class NotesFilterSection extends StatefulWidget {
  final NoteFilter filter;
  final Function(NoteFilter) onFilterChanged;

  const NotesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<NotesFilterSection> createState() => _NotesFilterSectionState();
}

class _NotesFilterSectionState extends State<NotesFilterSection> {
  late TextEditingController _nameController;
  late TextEditingController _contentQueryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name);
    _contentQueryController = TextEditingController(
      text: widget.filter.contentQuery,
    );
  }

  @override
  void didUpdateWidget(NotesFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _nameController,
      oldValue: oldWidget.filter.name ?? '',
      newValue: widget.filter.name ?? '',
    );
    syncTextController(
      controller: _contentQueryController,
      oldValue: oldWidget.filter.contentQuery ?? '',
      newValue: widget.filter.contentQuery ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentQueryController.dispose();
    super.dispose();
  }

  void _updateFilter(NoteFilter Function(NoteFilter) updater) {
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
            'Поиск по полям',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Название
          TextField(
            controller: _nameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название',
              hintText: 'Введите название...',
              prefixIcon: const Icon(Icons.title),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _nameController.clear();
                        _updateFilter((f) => f.copyWith(name: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(name: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Содержимое
          TextField(
            controller: _contentQueryController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Содержимое',
              hintText: 'Поиск по тексту заметки...',
              prefixIcon: const Icon(Icons.text_fields),
              suffixIcon: _contentQueryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _contentQueryController.clear();
                        _updateFilter((f) => f.copyWith(contentQuery: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(contentQuery: trimmed.isEmpty ? null : trimmed),
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
      title: const Text('Наличие данных'),
      initiallyExpanded: widget.filter.hasContent != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'С содержимым',
                value: widget.filter.hasContent,
                icon: Icons.notes,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasContent: value));
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
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: value == true
              ? colorScheme.primary.withValues(alpha: 0.1)
              : value == false
              ? colorScheme.error.withValues(alpha: 0.1)
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
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.6),
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
                label: 'По названию',
                field: NoteSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: NoteSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: NoteSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: NoteSortField.lastUsedAt,
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
    required NoteSortField field,
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
    return widget.filter.name != null ||
        widget.filter.contentQuery != null ||
        widget.filter.hasContent != null ||
        widget.filter.sortField != null;
  }

  void _clearNotesFilters() {
    _nameController.clear();
    _contentQueryController.clear();

    _updateFilter(
      (f) => f.copyWith(
        name: null,
        contentQuery: null,
        hasContent: null,
        sortField: null,
      ),
    );
  }
}
