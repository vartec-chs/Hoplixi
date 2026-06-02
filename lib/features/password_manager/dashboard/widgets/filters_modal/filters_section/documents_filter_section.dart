import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/document/document_types.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class DocumentsFilterSection extends StatefulWidget {
  final DocumentFilter filter;
  final Function(DocumentFilter) onFilterChanged;

  const DocumentsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<DocumentsFilterSection> createState() => _DocumentsFilterSectionState();
}

class _DocumentsFilterSectionState extends State<DocumentsFilterSection> {
  late TextEditingController _minPageCountController;
  late TextEditingController _maxPageCountController;

  @override
  void initState() {
    super.initState();
    _minPageCountController = TextEditingController(
      text: widget.filter.minPageCount?.toString() ?? '',
    );
    _maxPageCountController = TextEditingController(
      text: widget.filter.maxPageCount?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(DocumentsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _minPageCountController,
      oldValue: oldWidget.filter.minPageCount?.toString() ?? '',
      newValue: widget.filter.minPageCount?.toString() ?? '',
    );
    syncTextController(
      controller: _maxPageCountController,
      oldValue: oldWidget.filter.maxPageCount?.toString() ?? '',
      newValue: widget.filter.maxPageCount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minPageCountController.dispose();
    _maxPageCountController.dispose();
    super.dispose();
  }

  void _updateFilter(DocumentFilter Function(DocumentFilter) updater) {
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
              Icon(Icons.description, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры документов',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasDocumentsSpecificFilters())
                TextButton.icon(
                  onPressed: _clearDocumentsFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Типы документов
        _buildDocumentTypeSection(),

        const Divider(height: 1),

        // Количество страниц
        _buildPageCountSection(),

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
  // Типы документов
  // ============================================================================

  Widget _buildDocumentTypeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text('Тип документа'),
      initiallyExpanded: widget.filter.documentType != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DocumentType.values.map((type) {
              return ChoiceChip(
                label: Text(_getDocumentTypeLabel(type)),
                selected: widget.filter.documentType == type,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(documentType: selected ? type : null),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.passport:
        return 'Паспорт';
      case DocumentType.idCard:
        return 'ID карта';
      case DocumentType.driverLicense:
        return 'Вод. удостоверение';
      case DocumentType.contract:
        return 'Контракт';
      case DocumentType.invoice:
        return 'Инвойс';
      case DocumentType.receipt:
        return 'Чек';
      case DocumentType.certificate:
        return 'Сертификат';
      case DocumentType.insurance:
        return 'Страховка';
      case DocumentType.tax:
        return 'Налоги';
      case DocumentType.medical:
        return 'Медицина';
      case DocumentType.legal:
        return 'Юридический';
      case DocumentType.financial:
        return 'Финансовый';
      case DocumentType.other:
        return 'Другое';
    }
  }

  // ============================================================================
  // Количество страниц
  // ============================================================================

  Widget _buildPageCountSection() {
    return ExpansionTile(
      leading: const Icon(Icons.auto_stories),
      title: const Text('Количество страниц'),
      initiallyExpanded:
          widget.filter.minPageCount != null ||
          widget.filter.maxPageCount != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPageCountController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'От',
                    prefixIcon: const Icon(Icons.arrow_upward),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    _updateFilter((f) => f.copyWith(minPageCount: intValue));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxPageCountController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'До',
                    prefixIcon: const Icon(Icons.arrow_downward),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    _updateFilter((f) => f.copyWith(maxPageCount: intValue));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Наличие данных'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Актуальная версия',
                value: widget.filter.hasCurrentVersion,
                icon: Icons.update,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasCurrentVersion: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Есть хеш содержимого',
                value: widget.filter.hasAggregateHash,
                icon: Icons.fingerprint,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasAggregateHash: value));
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
    return widget.filter.hasCurrentVersion != null ||
        widget.filter.hasAggregateHash != null;
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
                field: DocumentSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: DocumentSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: DocumentSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: DocumentSortField.lastUsedAt,
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
    required DocumentSortField field,
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

  bool _hasDocumentsSpecificFilters() {
    return widget.filter.documentType != null ||
        widget.filter.minPageCount != null ||
        widget.filter.maxPageCount != null ||
        widget.filter.hasCurrentVersion != null ||
        widget.filter.hasAggregateHash != null ||
        widget.filter.sortField != null;
  }

  void _clearDocumentsFilters() {
    _minPageCountController.clear();
    _maxPageCountController.clear();

    _updateFilter(
      (f) => f.copyWith(
        documentType: null,
        minPageCount: null,
        maxPageCount: null,
        hasCurrentVersion: null,
        hasAggregateHash: null,
        sortField: null,
      ),
    );
  }
}
