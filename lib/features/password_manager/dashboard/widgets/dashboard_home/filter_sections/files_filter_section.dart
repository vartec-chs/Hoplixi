import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class FilesFilterSection extends StatefulWidget {
  final FilesFilter filter;
  final Function(FilesFilter) onFilterChanged;

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
  late TextEditingController _minFileSizeController;
  late TextEditingController _maxFileSizeController;
  late TextEditingController _extensionController;
  late TextEditingController _mimeTypeController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: widget.filter.fileName);
    _minFileSizeController = TextEditingController(
      text: widget.filter.minFileSize != null
          ? _formatBytes(widget.filter.minFileSize!)
          : '',
    );
    _maxFileSizeController = TextEditingController(
      text: widget.filter.maxFileSize != null
          ? _formatBytes(widget.filter.maxFileSize!)
          : '',
    );
    _extensionController = TextEditingController();
    _mimeTypeController = TextEditingController();
  }

  @override
  void didUpdateWidget(FilesFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.fileName != widget.filter.fileName) {
      _fileNameController.text = widget.filter.fileName ?? '';
    }
    if (oldWidget.filter.minFileSize != widget.filter.minFileSize) {
      _minFileSizeController.text = widget.filter.minFileSize != null
          ? _formatBytes(widget.filter.minFileSize!)
          : '';
    }
    if (oldWidget.filter.maxFileSize != widget.filter.maxFileSize) {
      _maxFileSizeController.text = widget.filter.maxFileSize != null
          ? _formatBytes(widget.filter.maxFileSize!)
          : '';
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _minFileSizeController.dispose();
    _maxFileSizeController.dispose();
    _extensionController.dispose();
    _mimeTypeController.dispose();
    super.dispose();
  }

  void _updateFilter(FilesFilter Function(FilesFilter) updater) {
    widget.onFilterChanged(updater(widget.filter));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int? _parseFileSize(String text) {
    final trimmed = text.trim().toUpperCase();
    if (trimmed.isEmpty) return null;

    final regex = RegExp(r'^(\d+(?:\.\d+)?)\s*(B|KB|MB|GB)?$');
    final match = regex.firstMatch(trimmed);
    if (match == null) return null;

    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) return null;

    final unit = match.group(2) ?? 'B';
    switch (unit) {
      case 'KB':
        return (value * 1024).toInt();
      case 'MB':
        return (value * 1024 * 1024).toInt();
      case 'GB':
        return (value * 1024 * 1024 * 1024).toInt();
      default:
        return value.toInt();
    }
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
              Icon(Icons.folder, color: colorScheme.primary),
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

        // Поиск по имени файла
        _buildFileNameFilter(),

        const Divider(height: 1),

        // Расширения файлов
        _buildExtensionsSection(),

        const Divider(height: 1),

        // MIME типы
        _buildMimeTypesSection(),

        const Divider(height: 1),

        // Размер файла
        _buildFileSizeSection(),

        const Divider(height: 1),

        // Пресеты типов файлов
        _buildFileTypePresets(),

        const Divider(height: 1),

        // Сортировка
        _buildSortingSection(),
      ],
    );
  }

  // ============================================================================
  // Поиск по имени файла
  // ============================================================================

  Widget _buildFileNameFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Имя файла',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fileNameController,
            decoration: primaryInputDecoration(
              context,
              hintText: 'Введите имя файла...',
              prefixIcon: const Icon(Icons.text_fields),
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
        ],
      ),
    );
  }

  // ============================================================================
  // Расширения файлов
  // ============================================================================

  Widget _buildExtensionsSection() {
    return ExpansionTile(
      leading: const Icon(Icons.extension),
      title: const Text('Расширения файлов'),
      subtitle: widget.filter.fileExtensions.isNotEmpty
          ? Text(
              '${widget.filter.fileExtensions.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.fileExtensions.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Добавление расширения
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _extensionController,
                      decoration: const InputDecoration(
                        hintText: 'Например: pdf, jpg, txt',
                        prefixIcon: Icon(Icons.add),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => _addExtension(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addExtension(_extensionController.text),
                  ),
                ],
              ),

              // Список выбранных расширений
              if (widget.filter.fileExtensions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.filter.fileExtensions.map((ext) {
                    return Chip(
                      label: Text('.$ext'),
                      onDeleted: () => _removeExtension(ext),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _addExtension(String extension) {
    final trimmed = extension.trim().toLowerCase().replaceAll('.', '');
    if (trimmed.isEmpty) return;
    if (widget.filter.fileExtensions.contains(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Расширение .$trimmed уже добавлено')),
      );
      return;
    }

    _extensionController.clear();
    _updateFilter(
      (f) => f.copyWith(fileExtensions: [...f.fileExtensions, trimmed]),
    );
  }

  void _removeExtension(String extension) {
    _updateFilter(
      (f) => f.copyWith(
        fileExtensions: f.fileExtensions.where((e) => e != extension).toList(),
      ),
    );
  }

  // ============================================================================
  // MIME типы
  // ============================================================================

  Widget _buildMimeTypesSection() {
    return ExpansionTile(
      leading: const Icon(Icons.data_object),
      title: const Text('MIME типы'),
      subtitle: widget.filter.mimeTypes.isNotEmpty
          ? Text(
              '${widget.filter.mimeTypes.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.mimeTypes.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Добавление MIME типа
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mimeTypeController,
                      decoration: const InputDecoration(
                        hintText: 'Например: image/png, application/pdf',
                        prefixIcon: Icon(Icons.add),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => _addMimeType(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addMimeType(_mimeTypeController.text),
                  ),
                ],
              ),

              // Список выбранных MIME типов
              if (widget.filter.mimeTypes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.filter.mimeTypes.map((mime) {
                    return Chip(
                      label: Text(mime),
                      onDeleted: () => _removeMimeType(mime),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _addMimeType(String mimeType) {
    final trimmed = mimeType.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    if (widget.filter.mimeTypes.contains(trimmed)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('MIME тип $trimmed уже добавлен')));
      return;
    }

    _mimeTypeController.clear();
    _updateFilter((f) => f.copyWith(mimeTypes: [...f.mimeTypes, trimmed]));
  }

  void _removeMimeType(String mimeType) {
    _updateFilter(
      (f) => f.copyWith(
        mimeTypes: f.mimeTypes.where((m) => m != mimeType).toList(),
      ),
    );
  }

  // ============================================================================
  // Размер файла
  // ============================================================================

  Widget _buildFileSizeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.storage),
      title: const Text('Размер файла'),
      initiallyExpanded:
          widget.filter.minFileSize != null ||
          widget.filter.maxFileSize != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Введите размер (например: 100 KB, 5 MB, 1 GB)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minFileSizeController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Минимум',
                        prefixIcon: const Icon(Icons.arrow_upward),
                        errorText: !widget.filter.isValidFileSizeRange
                            ? 'Неверный диапазон'
                            : null,
                      ),
                      onChanged: (value) {
                        final bytes = _parseFileSize(value);
                        _updateFilter((f) => f.copyWith(minFileSize: bytes));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxFileSizeController,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Максимум',
                        prefixIcon: const Icon(Icons.arrow_downward),
                        errorText: !widget.filter.isValidFileSizeRange
                            ? 'Неверный диапазон'
                            : null,
                      ),
                      onChanged: (value) {
                        final bytes = _parseFileSize(value);
                        _updateFilter((f) => f.copyWith(maxFileSize: bytes));
                      },
                    ),
                  ),
                ],
              ),

              // Быстрые пресеты размера
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSizePresetChip(
                    label: 'Маленькие (< 1 MB)',
                    onTap: () {
                      _minFileSizeController.text = '';
                      _maxFileSizeController.text = '1 MB';
                      _updateFilter(
                        (f) => f.copyWith(
                          minFileSize: null,
                          maxFileSize: 1024 * 1024,
                        ),
                      );
                    },
                  ),
                  _buildSizePresetChip(
                    label: 'Средние (1-100 MB)',
                    onTap: () {
                      _minFileSizeController.text = '1 MB';
                      _maxFileSizeController.text = '100 MB';
                      _updateFilter(
                        (f) => f.copyWith(
                          minFileSize: 1024 * 1024,
                          maxFileSize: 100 * 1024 * 1024,
                        ),
                      );
                    },
                  ),
                  _buildSizePresetChip(
                    label: 'Большие (> 100 MB)',
                    onTap: () {
                      _minFileSizeController.text = '100 MB';
                      _maxFileSizeController.text = '';
                      _updateFilter(
                        (f) => f.copyWith(
                          minFileSize: 100 * 1024 * 1024,
                          maxFileSize: null,
                        ),
                      );
                    },
                  ),
                ],
              ),

              if (widget.filter.minFileSize != null ||
                  widget.filter.maxFileSize != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _minFileSizeController.clear();
                      _maxFileSizeController.clear();
                      _updateFilter(
                        (f) => f.copyWith(minFileSize: null, maxFileSize: null),
                      );
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Сбросить размер'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizePresetChip({
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
  // Пресеты типов файлов
  // ============================================================================

  Widget _buildFileTypePresets() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрый выбор типов',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypePresetChip(
                label: 'Документы',
                icon: Icons.description,
                extensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
              ),
              _buildTypePresetChip(
                label: 'Изображения',
                icon: Icons.image,
                extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'],
              ),
              _buildTypePresetChip(
                label: 'Видео',
                icon: Icons.video_file,
                extensions: ['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv'],
              ),
              _buildTypePresetChip(
                label: 'Аудио',
                icon: Icons.audio_file,
                extensions: ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'],
              ),
              _buildTypePresetChip(
                label: 'Архивы',
                icon: Icons.folder_zip,
                extensions: ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypePresetChip({
    required String label,
    required IconData icon,
    required List<String> extensions,
  }) {
    final isActive = extensions.every(
      (ext) => widget.filter.fileExtensions.contains(ext),
    );

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isActive,
      onSelected: (selected) {
        if (selected) {
          // Добавить все расширения из пресета
          final newExtensions = {
            ...widget.filter.fileExtensions,
            ...extensions,
          }.toList();
          _updateFilter((f) => f.copyWith(fileExtensions: newExtensions));
        } else {
          // Удалить все расширения из пресета
          final newExtensions = widget.filter.fileExtensions
              .where((ext) => !extensions.contains(ext))
              .toList();
          _updateFilter((f) => f.copyWith(fileExtensions: newExtensions));
        }
      },
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
                field: FilesSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По имени файла',
                field: FilesSortField.fileName,
                icon: Icons.text_fields,
              ),
              _buildSortChip(
                label: 'По размеру',
                field: FilesSortField.fileSize,
                icon: Icons.storage,
              ),
              _buildSortChip(
                label: 'По расширению',
                field: FilesSortField.fileExtension,
                icon: Icons.extension,
              ),
              _buildSortChip(
                label: 'По MIME типу',
                field: FilesSortField.mimeType,
                icon: Icons.data_object,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: FilesSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: FilesSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: FilesSortField.lastAccessed,
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
    required FilesSortField field,
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
        widget.filter.fileExtensions.isNotEmpty ||
        widget.filter.mimeTypes.isNotEmpty ||
        widget.filter.minFileSize != null ||
        widget.filter.maxFileSize != null ||
        widget.filter.sortField != null;
  }

  void _clearFilesFilters() {
    _fileNameController.clear();
    _minFileSizeController.clear();
    _maxFileSizeController.clear();
    _extensionController.clear();
    _mimeTypeController.clear();

    _updateFilter(
      (f) => f.copyWith(
        fileName: null,
        fileExtensions: [],
        mimeTypes: [],
        minFileSize: null,
        maxFileSize: null,
        sortField: null,
      ),
    );
  }
}
