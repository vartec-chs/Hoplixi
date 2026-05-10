import 'package:flutter/material.dart';
import 'package:hoplixi/main_db/core/models/filter/index.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class PasswordFilterSection extends StatefulWidget {
  final PasswordsFilter filter;
  final Function(PasswordsFilter) onFilterChanged;

  const PasswordFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<PasswordFilterSection> createState() => _PasswordFilterSectionState();
}

class _PasswordFilterSectionState extends State<PasswordFilterSection> {
  late TextEditingController _nameController;
  late TextEditingController _loginController;
  late TextEditingController _emailController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name);
    _loginController = TextEditingController(text: widget.filter.login);
    _emailController = TextEditingController(text: widget.filter.email);
    _urlController = TextEditingController(text: widget.filter.url);
  }

  @override
  void didUpdateWidget(PasswordFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _nameController,
      oldValue: oldWidget.filter.name ?? '',
      newValue: widget.filter.name ?? '',
    );
    syncTextController(
      controller: _loginController,
      oldValue: oldWidget.filter.login ?? '',
      newValue: widget.filter.login ?? '',
    );
    syncTextController(
      controller: _emailController,
      oldValue: oldWidget.filter.email ?? '',
      newValue: widget.filter.email ?? '',
    );
    syncTextController(
      controller: _urlController,
      oldValue: oldWidget.filter.url ?? '',
      newValue: widget.filter.url ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _updateFilter(PasswordsFilter Function(PasswordsFilter) updater) {
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
              Icon(Icons.password, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры паролей',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasPasswordSpecificFilters())
                TextButton.icon(
                  onPressed: _clearPasswordFilters,
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

          // Логин
          TextField(
            controller: _loginController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Логин',
              hintText: 'Введите логин...',
              prefixIcon: const Icon(Icons.person),
              suffixIcon: _loginController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _loginController.clear();
                        _updateFilter((f) => f.copyWith(login: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(login: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Email
          TextField(
            controller: _emailController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Email',
              hintText: 'Введите email...',
              prefixIcon: const Icon(Icons.email),
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _emailController.clear();
                        _updateFilter((f) => f.copyWith(email: null));
                      },
                    )
                  : null,
              errorText: !widget.filter.isValidEmail
                  ? 'Неверный формат email'
                  : null,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(email: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // URL
          TextField(
            controller: _urlController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'URL',
              hintText: 'Введите URL...',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _urlController.clear();
                        _updateFilter((f) => f.copyWith(url: null));
                      },
                    )
                  : null,
              errorText: !widget.filter.isValidUrl
                  ? 'Неверный формат URL'
                  : null,
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(url: trimmed.isEmpty ? null : trimmed),
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
                label: 'С заметками',
                value: widget.filter.hasNotes,
                icon: Icons.note,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasNotes: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С URL',
                value: widget.filter.hasUrl,
                icon: Icons.link,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasUrl: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С логином',
                value: widget.filter.hasLogin,
                icon: Icons.person,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasLogin: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С email',
                value: widget.filter.hasEmail,
                icon: Icons.email,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasEmail: value));
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
        widget.filter.hasNotes != null ||
        widget.filter.hasUrl != null ||
        widget.filter.hasLogin != null ||
        widget.filter.hasEmail != null;
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
                field: PasswordsSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По логину',
                field: PasswordsSortField.login,
                icon: Icons.person,
              ),
              _buildSortChip(
                label: 'По email',
                field: PasswordsSortField.email,
                icon: Icons.email,
              ),
              _buildSortChip(
                label: 'По URL',
                field: PasswordsSortField.url,
                icon: Icons.link,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: PasswordsSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: PasswordsSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: PasswordsSortField.lastAccessed,
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
    required PasswordsSortField field,
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

  bool _hasPasswordSpecificFilters() {
    return widget.filter.name != null ||
        widget.filter.login != null ||
        widget.filter.email != null ||
        widget.filter.url != null ||
        widget.filter.hasDescription != null ||
        widget.filter.hasNotes != null ||
        widget.filter.hasUrl != null ||
        widget.filter.hasLogin != null ||
        widget.filter.hasEmail != null ||
        widget.filter.sortField != null;
  }

  void _clearPasswordFilters() {
    _nameController.clear();
    _loginController.clear();
    _emailController.clear();
    _urlController.clear();

    _updateFilter(
      (f) => f.copyWith(
        name: null,
        login: null,
        email: null,
        url: null,
        hasDescription: null,
        hasNotes: null,
        hasUrl: null,
        hasLogin: null,
        hasEmail: null,
        sortField: null,
      ),
    );
  }
}
