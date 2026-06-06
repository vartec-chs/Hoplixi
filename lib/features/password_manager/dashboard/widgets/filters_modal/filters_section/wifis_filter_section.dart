import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/wifi/wifi_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class WifisFilterSection extends StatefulWidget {
  final WifiFilter filter;
  final Function(WifiFilter) onFilterChanged;

  const WifisFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<WifisFilterSection> createState() => _WifisFilterSectionState();
}

class _WifisFilterSectionState extends State<WifisFilterSection> {
  late TextEditingController _ssidController;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController(text: widget.filter.ssid);
  }

  @override
  void didUpdateWidget(WifisFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _ssidController,
      oldValue: oldWidget.filter.ssid ?? '',
      newValue: widget.filter.ssid ?? '',
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    super.dispose();
  }

  void _updateFilter(WifiFilter Function(WifiFilter) updater) {
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
              Icon(Icons.wifi, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры Wi-Fi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasWifiSpecificFilters())
                TextButton.icon(
                  onPressed: _clearWifiFilters,
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

        // Типы защиты
        _buildSecurityTypeSection(),

        const Divider(height: 1),

        // Шифрование
        _buildEncryptionSection(),

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
            'Поиск',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // SSID
          TextField(
            controller: _ssidController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'SSID',
              hintText: 'Введите SSID (название сети)...',
              prefixIcon: const Icon(Icons.wifi_find),
              suffixIcon: _ssidController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _ssidController.clear();
                        _updateFilter((f) => f.copyWith(ssid: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(ssid: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы защиты
  // ============================================================================

  Widget _buildSecurityTypeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.security),
      title: const Text('Тип защиты'),
      initiallyExpanded: widget.filter.securityType != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WifiSecurityType.values.map((type) {
              return ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: widget.filter.securityType == type,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(securityType: selected ? type : null),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Шифрование
  // ============================================================================

  Widget _buildEncryptionSection() {
    return ExpansionTile(
      leading: const Icon(Icons.lock_outline),
      title: const Text('Шифрование'),
      initiallyExpanded: widget.filter.encryption != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WifiEncryptionType.values.map((enc) {
              return ChoiceChip(
                label: Text(enc.name.toUpperCase()),
                selected: widget.filter.encryption == enc,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(encryption: selected ? enc : null),
                  );
                },
              );
            }).toList(),
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
      title: const Text('Наличие полей'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'С паролем',
                value: widget.filter.hasPassword,
                icon: Icons.password,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasPassword: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Скрытая сеть',
                value: widget.filter.hiddenSsid,
                icon: Icons.visibility_off,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hiddenSsid: value));
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

  bool _hasActiveStatusFilters() {
    return widget.filter.hasPassword != null ||
        widget.filter.hiddenSsid != null;
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
                field: WifiSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По SSID',
                field: WifiSortField.ssid,
                icon: Icons.wifi,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: WifiSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: WifiSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: WifiSortField.lastUsedAt,
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
    required WifiSortField field,
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

  bool _hasWifiSpecificFilters() {
    return widget.filter.ssid != null ||
        widget.filter.securityType != null ||
        widget.filter.encryption != null ||
        widget.filter.hasPassword != null ||
        widget.filter.hiddenSsid != null ||
        widget.filter.sortField != null;
  }

  void _clearWifiFilters() {
    _ssidController.clear();

    _updateFilter(
      (f) => f.copyWith(
        ssid: null,
        securityType: null,
        encryption: null,
        hasPassword: null,
        hiddenSsid: null,
        sortField: null,
      ),
    );
  }
}
