import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class IdentitiesFilterSection extends StatefulWidget {
  final IdentityFilter filter;
  final Function(IdentityFilter) onFilterChanged;

  const IdentitiesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<IdentitiesFilterSection> createState() =>
      _IdentitiesFilterSectionState();
}

class _IdentitiesFilterSectionState extends State<IdentitiesFilterSection> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.filter.firstName);
    _lastNameController = TextEditingController(text: widget.filter.lastName);
    _displayNameController = TextEditingController(
      text: widget.filter.displayName,
    );
    _usernameController = TextEditingController(text: widget.filter.username);
    _emailController = TextEditingController(text: widget.filter.email);
  }

  @override
  void didUpdateWidget(IdentitiesFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _firstNameController,
      oldValue: oldWidget.filter.firstName ?? '',
      newValue: widget.filter.firstName ?? '',
    );
    syncTextController(
      controller: _lastNameController,
      oldValue: oldWidget.filter.lastName ?? '',
      newValue: widget.filter.lastName ?? '',
    );
    syncTextController(
      controller: _displayNameController,
      oldValue: oldWidget.filter.displayName ?? '',
      newValue: widget.filter.displayName ?? '',
    );
    syncTextController(
      controller: _usernameController,
      oldValue: oldWidget.filter.username ?? '',
      newValue: widget.filter.username ?? '',
    );
    syncTextController(
      controller: _emailController,
      oldValue: oldWidget.filter.email ?? '',
      newValue: widget.filter.email ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateFilter(IdentityFilter Function(IdentityFilter) updater) {
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
              Icon(Icons.badge, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры личностей',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasIdentitiesSpecificFilters())
                TextButton.icon(
                  onPressed: _clearIdentitiesFilters,
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

          // Имя и Фамилия
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firstNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Имя',
                    hintText: 'Иван',
                    suffixIcon: _firstNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _firstNameController.clear();
                              _updateFilter((f) => f.copyWith(firstName: null));
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim();
                    _updateFilter(
                      (f) => f.copyWith(
                        firstName: trimmed.isEmpty ? null : trimmed,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lastNameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Фамилия',
                    hintText: 'Петров',
                    suffixIcon: _lastNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _lastNameController.clear();
                              _updateFilter((f) => f.copyWith(lastName: null));
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim();
                    _updateFilter(
                      (f) => f.copyWith(
                        lastName: trimmed.isEmpty ? null : trimmed,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Отображаемое имя
          TextField(
            controller: _displayNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Отображаемое имя',
              hintText: 'Например: Work Identity...',
              prefixIcon: const Icon(Icons.account_box_outlined),
              suffixIcon: _displayNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _displayNameController.clear();
                        _updateFilter((f) => f.copyWith(displayName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(displayName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Имя пользователя и Email
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Username',
                    hintText: 'ivan123',
                    suffixIcon: _usernameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _usernameController.clear();
                              _updateFilter((f) => f.copyWith(username: null));
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim();
                    _updateFilter(
                      (f) => f.copyWith(
                        username: trimmed.isEmpty ? null : trimmed,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Email',
                    hintText: 'work@mail.ru',
                    suffixIcon: _emailController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _emailController.clear();
                              _updateFilter((f) => f.copyWith(email: null));
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim();
                    _updateFilter(
                      (f) =>
                          f.copyWith(email: trimmed.isEmpty ? null : trimmed),
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
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Наличие документов'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Паспорт',
                value: widget.filter.hasPassportNumber,
                icon: Icons.assignment_ind_outlined,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasPassportNumber: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Вод. удостоверение',
                value: widget.filter.hasDriverLicenseNumber,
                icon: Icons.directions_car_outlined,
                onChanged: (value) {
                  _updateFilter(
                    (f) => f.copyWith(hasDriverLicenseNumber: value),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'ИНН / Налоговый ID',
                value: widget.filter.hasTaxId,
                icon: Icons.receipt_long_outlined,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasTaxId: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Национальный ID',
                value: widget.filter.hasNationalId,
                icon: Icons.badge_outlined,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasNationalId: value));
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
    return widget.filter.hasPassportNumber != null ||
        widget.filter.hasDriverLicenseNumber != null ||
        widget.filter.hasTaxId != null ||
        widget.filter.hasNationalId != null;
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
                field: IdentitySortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По отбр. имени',
                field: IdentitySortField.displayName,
                icon: Icons.account_box,
              ),
              _buildSortChip(
                label: 'По username',
                field: IdentitySortField.username,
                icon: Icons.person,
              ),
              _buildSortChip(
                label: 'По email',
                field: IdentitySortField.email,
                icon: Icons.email,
              ),
              _buildSortChip(
                label: 'По компании',
                field: IdentitySortField.company,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: IdentitySortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: IdentitySortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: IdentitySortField.lastUsedAt,
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
    required IdentitySortField field,
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

  bool _hasIdentitiesSpecificFilters() {
    return widget.filter.firstName != null ||
        widget.filter.lastName != null ||
        widget.filter.displayName != null ||
        widget.filter.username != null ||
        widget.filter.email != null ||
        widget.filter.hasPassportNumber != null ||
        widget.filter.hasDriverLicenseNumber != null ||
        widget.filter.hasTaxId != null ||
        widget.filter.hasNationalId != null ||
        widget.filter.sortField != null;
  }

  void _clearIdentitiesFilters() {
    _firstNameController.clear();
    _lastNameController.clear();
    _displayNameController.clear();
    _usernameController.clear();
    _emailController.clear();

    _updateFilter(
      (f) => f.copyWith(
        firstName: null,
        lastName: null,
        displayName: null,
        username: null,
        email: null,
        hasPassportNumber: null,
        hasDriverLicenseNumber: null,
        hasTaxId: null,
        hasNationalId: null,
        sortField: null,
      ),
    );
  }
}
