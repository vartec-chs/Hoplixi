import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/license_key/license_key_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class LicenseKeysFilterSection extends StatefulWidget {
  final LicenseKeyFilter filter;
  final Function(LicenseKeyFilter) onFilterChanged;

  const LicenseKeysFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<LicenseKeysFilterSection> createState() =>
      _LicenseKeysFilterSectionState();
}

class _LicenseKeysFilterSectionState extends State<LicenseKeysFilterSection> {
  late TextEditingController _productNameController;
  late TextEditingController _vendorController;
  late TextEditingController _orderNumberController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.filter.productName,
    );
    _vendorController = TextEditingController(text: widget.filter.vendor);
    _orderNumberController = TextEditingController(
      text: widget.filter.orderNumber,
    );
  }

  @override
  void didUpdateWidget(LicenseKeysFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _productNameController,
      oldValue: oldWidget.filter.productName ?? '',
      newValue: widget.filter.productName ?? '',
    );
    syncTextController(
      controller: _vendorController,
      oldValue: oldWidget.filter.vendor ?? '',
      newValue: widget.filter.vendor ?? '',
    );
    syncTextController(
      controller: _orderNumberController,
      oldValue: oldWidget.filter.orderNumber ?? '',
      newValue: widget.filter.orderNumber ?? '',
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _vendorController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  void _updateFilter(LicenseKeyFilter Function(LicenseKeyFilter) updater) {
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
              Icon(Icons.vpn_key, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры лицензий',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasLicenseKeysSpecificFilters())
                TextButton.icon(
                  onPressed: _clearLicenseKeysFilters,
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

        // Типы лицензий
        _buildLicenseTypeSection(),

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

          // Продукт
          TextField(
            controller: _productNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Продукт',
              hintText: 'Например: IntelliJ IDEA...',
              prefixIcon: const Icon(Icons.apps),
              suffixIcon: _productNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _productNameController.clear();
                        _updateFilter((f) => f.copyWith(productName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(productName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Поставщик (Vendor)
          TextField(
            controller: _vendorController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Поставщик',
              hintText: 'Например: JetBrains, Adobe...',
              prefixIcon: const Icon(Icons.business),
              suffixIcon: _vendorController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _vendorController.clear();
                        _updateFilter((f) => f.copyWith(vendor: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(vendor: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Номер заказа
          TextField(
            controller: _orderNumberController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Номер заказа',
              hintText: 'Введите номер заказа или чека...',
              prefixIcon: const Icon(Icons.receipt_long),
              suffixIcon: _orderNumberController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _orderNumberController.clear();
                        _updateFilter((f) => f.copyWith(orderNumber: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(orderNumber: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы лицензий
  // ============================================================================

  Widget _buildLicenseTypeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.sell),
      title: const Text('Тип лицензии'),
      initiallyExpanded: widget.filter.licenseType != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LicenseType.values.map((type) {
              return ChoiceChip(
                label: Text(_getLicenseTypeLabel(type)),
                selected: widget.filter.licenseType == type,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(licenseType: selected ? type : null),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getLicenseTypeLabel(LicenseType type) {
    switch (type) {
      case LicenseType.perpetual:
        return 'Бессрочная';
      case LicenseType.subscription:
        return 'Подписка';
      case LicenseType.trial:
        return 'Пробная';
      case LicenseType.volume:
        return 'Корпоративная';
      case LicenseType.oem:
        return 'OEM';
      case LicenseType.educational:
        return 'Учебная';
      case LicenseType.openSource:
        return 'Open Source';
      case LicenseType.other:
        return 'Другая';
    }
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
                label: 'Есть срок действия',
                value: widget.filter.hasExpiration,
                icon: Icons.event_busy,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasExpiration: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Есть дата продления',
                value: widget.filter.hasRenewal,
                icon: Icons.autorenew,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasRenewal: value));
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
    return widget.filter.hasExpiration != null || widget.filter.hasRenewal != null;
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
                field: LicenseKeySortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По продукту',
                field: LicenseKeySortField.productName,
                icon: Icons.apps,
              ),
              _buildSortChip(
                label: 'По поставщику',
                field: LicenseKeySortField.vendor,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По типу',
                field: LicenseKeySortField.licenseType,
                icon: Icons.sell,
              ),
              _buildSortChip(
                label: 'По дате покупки',
                field: LicenseKeySortField.purchaseDate,
                icon: Icons.shopping_cart,
              ),
              _buildSortChip(
                label: 'По дате окончания',
                field: LicenseKeySortField.validTo,
                icon: Icons.event_busy,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: LicenseKeySortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: LicenseKeySortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: LicenseKeySortField.lastUsedAt,
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
    required LicenseKeySortField field,
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

  bool _hasLicenseKeysSpecificFilters() {
    return widget.filter.productName != null ||
        widget.filter.vendor != null ||
        widget.filter.licenseType != null ||
        widget.filter.orderNumber != null ||
        widget.filter.hasExpiration != null ||
        widget.filter.hasRenewal != null ||
        widget.filter.sortField != null;
  }

  void _clearLicenseKeysFilters() {
    _productNameController.clear();
    _vendorController.clear();
    _orderNumberController.clear();

    _updateFilter(
      (f) => f.copyWith(
        productName: null,
        vendor: null,
        licenseType: null,
        orderNumber: null,
        hasExpiration: null,
        hasRenewal: null,
        sortField: null,
      ),
    );
  }
}
