import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class DocumentsFilterSection extends StatefulWidget {
  final DocumentsFilter filter;
  final Function(DocumentsFilter) onFilterChanged;

  const DocumentsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<DocumentsFilterSection> createState() => _DocumentsFilterSectionState();
}

class _DocumentsFilterSectionState extends State<DocumentsFilterSection> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _aggregatedTextController;
  late TextEditingController _minPageCountController;
  late TextEditingController _maxPageCountController;
  late TextEditingController _documentTypeController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.filter.titleQuery);
    _descriptionController = TextEditingController(
      text: widget.filter.descriptionQuery,
    );
    _aggregatedTextController = TextEditingController(
      text: widget.filter.aggregatedTextQuery,
    );
    _minPageCountController = TextEditingController(
      text: widget.filter.minPageCount?.toString() ?? '',
    );
    _maxPageCountController = TextEditingController(
      text: widget.filter.maxPageCount?.toString() ?? '',
    );
    _documentTypeController = TextEditingController();
  }

  @override
  void didUpdateWidget(DocumentsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.titleQuery != widget.filter.titleQuery) {
      _titleController.text = widget.filter.titleQuery ?? '';
    }
    if (oldWidget.filter.descriptionQuery != widget.filter.descriptionQuery) {
      _descriptionController.text = widget.filter.descriptionQuery ?? '';
    }
    if (oldWidget.filter.aggregatedTextQuery !=
        widget.filter.aggregatedTextQuery) {
      _aggregatedTextController.text = widget.filter.aggregatedTextQuery ?? '';
    }
    if (oldWidget.filter.minPageCount != widget.filter.minPageCount) {
      _minPageCountController.text =
          widget.filter.minPageCount?.toString() ?? '';
    }
    if (oldWidget.filter.maxPageCount != widget.filter.maxPageCount) {
      _maxPageCountController.text =
          widget.filter.maxPageCount?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aggregatedTextController.dispose();
    _minPageCountController.dispose();
    _maxPageCountController.dispose();
    _documentTypeController.dispose();
    super.dispose();
  }

  void _updateFilter(DocumentsFilter Function(DocumentsFilter) updater) {
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

        // Поиск по заголовку
        _buildTitleFilter(),

        const Divider(height: 1),

        // Поиск по описанию
        _buildDescriptionFilter(),

        const Divider(height: 1),

        // Поиск по тексту (OCR)
        _buildAggregatedTextFilter(),

        const Divider(height: 1),

        // Типы документов
        _buildDocumentTypesSection(),

        const Divider(height: 1),

        // Количество страниц
        _buildPageCountFilter(),

        const Divider(height: 1),

        // Сортировка по полям
        _buildSortFieldFilter(),
      ],
    );
  }

  // ============================================================================
  // Поиск по заголовку
  // ============================================================================

  Widget _buildTitleFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поиск по заголовку',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: primaryInputDecoration(
              context,
              hintText: 'Введите текст для поиска в заголовке...',
              prefixIcon: const Icon(Icons.title),
              suffixIcon: _titleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _titleController.clear();
                        _updateFilter((f) => f.copyWith(titleQuery: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(titleQuery: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Поиск по описанию
  // ============================================================================

  Widget _buildDescriptionFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поиск по описанию',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: primaryInputDecoration(
              context,
              hintText: 'Введите текст для поиска в описании...',
              prefixIcon: const Icon(Icons.notes),
              suffixIcon: _descriptionController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _descriptionController.clear();
                        _updateFilter(
                          (f) => f.copyWith(descriptionQuery: null),
                        );
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(
                  descriptionQuery: trimmed.isEmpty ? null : trimmed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Поиск по тексту (OCR)
  // ============================================================================

  Widget _buildAggregatedTextFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поиск по распознанному тексту',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Поиск в тексте, распознанном из изображений документа (OCR)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aggregatedTextController,
            decoration: primaryInputDecoration(
              context,
              hintText: 'Введите текст для поиска в OCR...',
              prefixIcon: const Icon(Icons.text_fields),
              suffixIcon: _aggregatedTextController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _aggregatedTextController.clear();
                        _updateFilter(
                          (f) => f.copyWith(aggregatedTextQuery: null),
                        );
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(
                  aggregatedTextQuery: trimmed.isEmpty ? null : trimmed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы документов
  // ============================================================================

  Widget _buildDocumentTypesSection() {
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text('Типы документов'),
      initiallyExpanded: widget.filter.documentTypes.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Список выбранных типов
              if (widget.filter.documentTypes.isNotEmpty) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: widget.filter.documentTypes.map((type) {
                    return Chip(
                      label: Text(_getDocumentTypeLabel(type)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeDocumentType(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Поле добавления нового типа
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _documentTypeController,
                      decoration: primaryInputDecoration(
                        context,
                        hintText: 'Введите тип документа...',
                        prefixIcon: const Icon(Icons.add),
                      ),
                      onSubmitted: (value) => _addDocumentType(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _addDocumentType(_documentTypeController.text);
                    },
                    icon: const Icon(Icons.add_circle),
                    tooltip: 'Добавить тип',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Быстрые пресеты
              Text(
                'Быстрый выбор:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _commonDocumentTypes.map((type) {
                  final isSelected = widget.filter.documentTypes.contains(
                    type.toLowerCase(),
                  );
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _addDocumentType(type);
                      } else {
                        _removeDocumentType(type);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final List<String> _commonDocumentTypes = [
    'Паспорт',
    'Водительское удостоверение',
    'Договор',
    'Сертификат',
    'Диплом',
    'Справка',
    'Удостоверение',
    'Квитанция',
    'Чек',
  ];

  String _getDocumentTypeLabel(String type) {
    // Первую букву делаем заглавной для отображения
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1);
  }

  void _addDocumentType(String type) {
    final trimmed = type.trim();
    if (trimmed.isEmpty) return;

    final normalized = trimmed.toLowerCase();
    if (widget.filter.documentTypes.contains(normalized)) return;

    final updated = [...widget.filter.documentTypes, normalized];
    _updateFilter((f) => f.copyWith(documentTypes: updated));

    _documentTypeController.clear();
  }

  void _removeDocumentType(String type) {
    final updated = widget.filter.documentTypes
        .where((t) => t != type.toLowerCase())
        .toList();
    _updateFilter((f) => f.copyWith(documentTypes: updated));
  }

  // ============================================================================
  // Количество страниц
  // ============================================================================

  Widget _buildPageCountFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Количество страниц',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPageCountController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'От',
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final count = int.tryParse(value);
                    _updateFilter((f) => f.copyWith(minPageCount: count));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPageCountController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'До',
                    hintText: '∞',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final count = int.tryParse(value);
                    _updateFilter((f) => f.copyWith(maxPageCount: count));
                  },
                ),
              ),
            ],
          ),
          if (!widget.filter.isValidPageCountRange) ...[
            const SizedBox(height: 8),
            Text(
              'Некорректный диапазон страниц',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // Сортировка по полям
  // ============================================================================

  Widget _buildSortFieldFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сортировка документов',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: DocumentsSortField.values.map((sortField) {
              final isSelected = widget.filter.sortField == sortField;
              return ChoiceChip(
                label: Text(_getSortFieldLabel(sortField)),
                selected: isSelected,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(sortField: selected ? sortField : null),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSortFieldLabel(DocumentsSortField sortField) {
    switch (sortField) {
      case DocumentsSortField.title:
        return 'Заголовок';
      case DocumentsSortField.documentType:
        return 'Тип документа';
      case DocumentsSortField.pageCount:
        return 'Количество страниц';
      case DocumentsSortField.createdAt:
        return 'Дата создания';
      case DocumentsSortField.modifiedAt:
        return 'Дата изменения';
      case DocumentsSortField.lastUsedAt:
        return 'Последнее использование';
    }
  }

  // ============================================================================
  // Утилиты
  // ============================================================================

  bool _hasDocumentsSpecificFilters() {
    return widget.filter.titleQuery != null ||
        widget.filter.descriptionQuery != null ||
        widget.filter.aggregatedTextQuery != null ||
        widget.filter.documentTypes.isNotEmpty ||
        widget.filter.minPageCount != null ||
        widget.filter.maxPageCount != null ||
        widget.filter.sortField != null;
  }

  void _clearDocumentsFilters() {
    _titleController.clear();
    _descriptionController.clear();
    _aggregatedTextController.clear();
    _minPageCountController.clear();
    _maxPageCountController.clear();
    _documentTypeController.clear();

    _updateFilter(
      (f) => f.copyWith(
        titleQuery: null,
        descriptionQuery: null,
        aggregatedTextQuery: null,
        documentTypes: const [],
        minPageCount: null,
        maxPageCount: null,
        sortField: null,
      ),
    );
  }
}
