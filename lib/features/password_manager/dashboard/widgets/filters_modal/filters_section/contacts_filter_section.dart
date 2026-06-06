import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class ContactsFilterSection extends StatefulWidget {
  final ContactFilter filter;
  final Function(ContactFilter) onFilterChanged;

  const ContactsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<ContactsFilterSection> createState() => _ContactsFilterSectionState();
}

class _ContactsFilterSectionState extends State<ContactsFilterSection> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.filter.firstName);
    _lastNameController = TextEditingController(text: widget.filter.lastName);
    _phoneController = TextEditingController(text: widget.filter.phone);
    _emailController = TextEditingController(text: widget.filter.email);
    _companyController = TextEditingController(text: widget.filter.company);
  }

  @override
  void didUpdateWidget(ContactsFilterSection oldWidget) {
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
      controller: _phoneController,
      oldValue: oldWidget.filter.phone ?? '',
      newValue: widget.filter.phone ?? '',
    );
    syncTextController(
      controller: _emailController,
      oldValue: oldWidget.filter.email ?? '',
      newValue: widget.filter.email ?? '',
    );
    syncTextController(
      controller: _companyController,
      oldValue: oldWidget.filter.company ?? '',
      newValue: widget.filter.company ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _updateFilter(ContactFilter Function(ContactFilter) updater) {
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
              Icon(Icons.contacts, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры контактов',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasContactsSpecificFilters())
                TextButton.icon(
                  onPressed: _clearContactsFilters,
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

          // Имя
          TextField(
            controller: _firstNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя',
              hintText: 'Введите имя...',
              prefixIcon: const Icon(Icons.person),
              suffixIcon: _firstNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
                (f) => f.copyWith(firstName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Фамилия
          TextField(
            controller: _lastNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Фамилия',
              hintText: 'Введите фамилию...',
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: _lastNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
                (f) => f.copyWith(lastName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Телефон
          TextField(
            controller: _phoneController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Телефон',
              hintText: 'Введите номер телефона...',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: _phoneController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _phoneController.clear();
                        _updateFilter((f) => f.copyWith(phone: null));
                      },
                    )
                  : null,
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(phone: trimmed.isEmpty ? null : trimmed),
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

          // Компания
          TextField(
            controller: _companyController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Компания',
              hintText: 'Введите название компании...',
              prefixIcon: const Icon(Icons.business),
              suffixIcon: _companyController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _companyController.clear();
                        _updateFilter((f) => f.copyWith(company: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(company: trimmed.isEmpty ? null : trimmed),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTriStateCheckbox(
            label: 'Экстренный контакт',
            value: widget.filter.isEmergencyContact,
            icon: Icons.emergency,
            onChanged: (value) {
              _updateFilter((f) => f.copyWith(isEmergencyContact: value));
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
                field: ContactSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По имени',
                field: ContactSortField.firstName,
                icon: Icons.person,
              ),
              _buildSortChip(
                label: 'По фамилии',
                field: ContactSortField.lastName,
                icon: Icons.person_outline,
              ),
              _buildSortChip(
                label: 'По компании',
                field: ContactSortField.company,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: ContactSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: ContactSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: ContactSortField.lastUsedAt,
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
    required ContactSortField field,
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

  bool _hasContactsSpecificFilters() {
    return widget.filter.firstName != null ||
        widget.filter.lastName != null ||
        widget.filter.phone != null ||
        widget.filter.email != null ||
        widget.filter.company != null ||
        widget.filter.isEmergencyContact != null ||
        widget.filter.sortField != null;
  }

  void _clearContactsFilters() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _companyController.clear();

    _updateFilter(
      (f) => f.copyWith(
        firstName: null,
        lastName: null,
        phone: null,
        email: null,
        company: null,
        isEmergencyContact: null,
        sortField: null,
      ),
    );
  }
}
