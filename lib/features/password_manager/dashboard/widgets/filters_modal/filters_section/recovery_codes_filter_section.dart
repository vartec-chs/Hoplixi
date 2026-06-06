import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';

class RecoveryCodesFilterSection extends StatefulWidget {
  final RecoveryCodesFilter filter;
  final Function(RecoveryCodesFilter) onFilterChanged;

  const RecoveryCodesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<RecoveryCodesFilterSection> createState() =>
      _RecoveryCodesFilterSectionState();
}

class _RecoveryCodesFilterSectionState
    extends State<RecoveryCodesFilterSection> {
  void _updateFilter(
    RecoveryCodesFilter Function(RecoveryCodesFilter) updater,
  ) {
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
              Icon(Icons.vibration, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры кодов восстановления',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasRecoveryCodesSpecificFilters())
                TextButton.icon(
                  onPressed: _clearRecoveryCodesFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

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
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTriStateCheckbox(
            label: 'Одноразовые',
            value: widget.filter.oneTime,
            icon: Icons.looks_one,
            onChanged: (value) {
              _updateFilter((f) => f.copyWith(oneTime: value));
            },
          ),
          const SizedBox(height: 8),
          _buildTriStateCheckbox(
            label: 'Есть коды',
            value: widget.filter.hasCodes,
            icon: Icons.list_alt,
            onChanged: (value) {
              _updateFilter((f) => f.copyWith(hasCodes: value));
            },
          ),
        ],
      ),
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
                field: RecoveryCodesSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По дате генерации',
                field: RecoveryCodesSortField.generatedAt,
                icon: Icons.auto_awesome,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: RecoveryCodesSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: RecoveryCodesSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: RecoveryCodesSortField.lastUsedAt,
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
    required RecoveryCodesSortField field,
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

  bool _hasRecoveryCodesSpecificFilters() {
    return widget.filter.oneTime != null ||
        widget.filter.hasCodes != null ||
        widget.filter.generatedAfter != null ||
        widget.filter.generatedBefore != null ||
        widget.filter.sortField != null;
  }

  void _clearRecoveryCodesFilters() {
    _updateFilter(
      (f) => f.copyWith(
        oneTime: null,
        hasCodes: null,
        generatedAfter: null,
        generatedBefore: null,
        sortField: null,
      ),
    );
  }
}
