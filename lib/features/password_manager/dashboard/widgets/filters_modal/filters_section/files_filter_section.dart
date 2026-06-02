import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/file/file_metadata.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class FilesFilterSection extends StatefulWidget {
  final FileFilter filter;
  final Function(FileFilter) onFilterChanged;

  const FilesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<FilesFilterSection> createState() => _FilesFilterSectionState();
}

class _FilesFilterSectionState extends State<FilesFilterSection> {
  late TextEditingController _fileNameController;
  late TextEditingController _extensionController;
  late TextEditingController _mimeTypeController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.filter.fileName);
    _extensionController = TextEditingController(
      text: widget.filter.fileExtension,
    );
    _mimeTypeController = TextEditingController(text: widget.filter.mimeType);
  }

  @override
  void didUpdateWidget(FilesFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _fileNameController,
      oldValue: oldWidget.filter.fileName ?? '',
      newValue: widget.filter.fileName ?? '',
    );
    syncTextController(
      controller: _extensionController,
      oldValue: oldWidget.filter.fileExtension ?? '',
      newValue: widget.filter.fileExtension ?? '',
    );
    syncTextController(
      controller: _mimeTypeController,
      oldValue: oldWidget.filter.mimeType ?? '',
      newValue: widget.filter.mimeType ?? '',
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _extensionController.dispose();
    _mimeTypeController.dispose();
    super.dispose();
  }

  void _updateFilter(FileFilter Function(FileFilter) updater) {
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
              Icon(Icons.insert_drive_file, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры файлов',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasFilesSpecificFilters())
                TextButton.icon(
                  onPressed: _clearFilesFilters,
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

        // Статусы
        _buildStatusesSection(),

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

          // Имя файла
          TextField(
            controller: _fileNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя файла',
              hintText: 'Введите имя файла...',
              prefixIcon: const Icon(Icons.drive_file_rename_outline),
              suffixIcon: _fileNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _fileNameController.clear();
                        _updateFilter((f) => f.copyWith(fileName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(fileName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Расширение
              Expanded(
                child: TextField(
                  controller: _extensionController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Расширение',
                    hintText: 'pdf, jpg...',
                    suffixIcon: _extensionController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _extensionController.clear();
                              _updateFilter(
                                (f) => f.copyWith(fileExtension: null),
                              );
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim().toLowerCase();
                    _updateFilter(
                      (f) => f.copyWith(
                        fileExtension: trimmed.isEmpty ? null : trimmed,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // MIME тип
              Expanded(
                child: TextField(
                  controller: _mimeTypeController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'MIME тип',
                    hintText: 'image/jpeg...',
                    suffixIcon: _mimeTypeController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _mimeTypeController.clear();
                              _updateFilter((f) => f.copyWith(mimeType: null));
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim().toLowerCase();
                    _updateFilter(
                      (f) => f.copyWith(
                        mimeType: trimmed.isEmpty ? null : trimmed,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Статусы
  // ============================================================================

  Widget _buildStatusesSection() {
    return ExpansionTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Статус файла'),
      initiallyExpanded:
          widget.filter.availabilityStatus != null ||
          widget.filter.integrityStatus != null,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Доступность',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FileAvailabilityStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(_getAvailabilityLabel(status)),
                    selected: widget.filter.availabilityStatus == status,
                    onSelected: (selected) {
                      _updateFilter(
                        (f) => f.copyWith(
                          availabilityStatus: selected ? status : null,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Целостность',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FileIntegrityStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(_getIntegrityLabel(status)),
                    selected: widget.filter.integrityStatus == status,
                    onSelected: (selected) {
                      _updateFilter(
                        (f) => f.copyWith(
                          integrityStatus: selected ? status : null,
                        ),
                      );
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

  String _getAvailabilityLabel(FileAvailabilityStatus status) {
    switch (status) {
      case FileAvailabilityStatus.available:
        return 'Доступен';
      case FileAvailabilityStatus.missing:
        return 'Пропал';
      case FileAvailabilityStatus.deleted:
        return 'Удален';
    }
  }

  String _getIntegrityLabel(FileIntegrityStatus status) {
    switch (status) {
      case FileIntegrityStatus.unknown:
        return 'Неизвестно';
      case FileIntegrityStatus.valid:
        return 'Цел';
      case FileIntegrityStatus.corrupted:
        return 'Поврежден';
    }
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
                field: FileSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По имени файла',
                field: FileSortField.fileName,
                icon: Icons.drive_file_rename_outline,
              ),
              _buildSortChip(
                label: 'По размеру',
                field: FileSortField.fileSize,
                icon: Icons.sd_storage,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: FileSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: FileSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: FileSortField.lastUsedAt,
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
    required FileSortField field,
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

  bool _hasFilesSpecificFilters() {
    return widget.filter.fileName != null ||
        widget.filter.fileExtension != null ||
        widget.filter.mimeType != null ||
        widget.filter.availabilityStatus != null ||
        widget.filter.integrityStatus != null ||
        widget.filter.sortField != null;
  }

  void _clearFilesFilters() {
    _fileNameController.clear();
    _extensionController.clear();
    _mimeTypeController.clear();

    _updateFilter(
      (f) => f.copyWith(
        fileName: null,
        fileExtension: null,
        mimeType: null,
        availabilityStatus: null,
        integrityStatus: null,
        sortField: null,
      ),
    );
  }
}
