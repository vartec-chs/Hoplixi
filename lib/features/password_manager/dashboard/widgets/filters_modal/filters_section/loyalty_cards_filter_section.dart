import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/loyalty_card/loyalty_card_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class LoyaltyCardsFilterSection extends StatefulWidget {
  final LoyaltyCardFilter filter;
  final Function(LoyaltyCardFilter) onFilterChanged;

  const LoyaltyCardsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<LoyaltyCardsFilterSection> createState() =>
      _LoyaltyCardsFilterSectionState();
}

class _LoyaltyCardsFilterSectionState extends State<LoyaltyCardsFilterSection> {
  late TextEditingController _programNameController;
  late TextEditingController _issuerController;

  @override
  void initState() {
    super.initState();
    _programNameController = TextEditingController(
      text: widget.filter.programName,
    );
    _issuerController = TextEditingController(text: widget.filter.issuer);
  }

  @override
  void didUpdateWidget(LoyaltyCardsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _programNameController,
      oldValue: oldWidget.filter.programName ?? '',
      newValue: widget.filter.programName ?? '',
    );
    syncTextController(
      controller: _issuerController,
      oldValue: oldWidget.filter.issuer ?? '',
      newValue: widget.filter.issuer ?? '',
    );
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  void _updateFilter(LoyaltyCardFilter Function(LoyaltyCardFilter) updater) {
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
              Icon(Icons.card_membership, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры карт лояльности',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasLoyaltyCardsSpecificFilters())
                TextButton.icon(
                  onPressed: _clearLoyaltyCardsFilters,
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

        // Типы штрихкодов
        _buildBarcodeTypeSection(),

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

          // Программа
          TextField(
            controller: _programNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Программа лояльности',
              hintText: 'Например: Пятерочка, Магнит...',
              prefixIcon: const Icon(Icons.storefront),
              suffixIcon: _programNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _programNameController.clear();
                        _updateFilter((f) => f.copyWith(programName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(programName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Issuer
          TextField(
            controller: _issuerController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Эмитент (Issuer)',
              hintText: 'Например: X5 Group...',
              prefixIcon: const Icon(Icons.business),
              suffixIcon: _issuerController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _issuerController.clear();
                        _updateFilter((f) => f.copyWith(issuer: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(issuer: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы штрихкодов
  // ============================================================================

  Widget _buildBarcodeTypeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.qr_code_scanner),
      title: const Text('Тип штрихкода'),
      initiallyExpanded: widget.filter.barcodeType != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LoyaltyBarcodeType.values.map((type) {
              return ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: widget.filter.barcodeType == type,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(barcodeType: selected ? type : null),
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
      title: const Text('Наличие данных'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Есть номер карты',
                value: widget.filter.hasCardNumber,
                icon: Icons.numbers,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasCardNumber: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Есть штрихкод',
                value: widget.filter.hasBarcodeValue,
                icon: Icons.qr_code,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasBarcodeValue: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Есть пароль',
                value: widget.filter.hasPassword,
                icon: Icons.password,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasPassword: value));
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
    return widget.filter.hasCardNumber != null ||
        widget.filter.hasBarcodeValue != null ||
        widget.filter.hasPassword != null;
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
                field: LoyaltyCardSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По программе',
                field: LoyaltyCardSortField.programName,
                icon: Icons.storefront,
              ),
              _buildSortChip(
                label: 'По эмитенту',
                field: LoyaltyCardSortField.issuer,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По дате окончания',
                field: LoyaltyCardSortField.validTo,
                icon: Icons.event_busy,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: LoyaltyCardSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: LoyaltyCardSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: LoyaltyCardSortField.lastUsedAt,
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
    required LoyaltyCardSortField field,
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

  bool _hasLoyaltyCardsSpecificFilters() {
    return widget.filter.programName != null ||
        widget.filter.issuer != null ||
        widget.filter.barcodeType != null ||
        widget.filter.hasCardNumber != null ||
        widget.filter.hasBarcodeValue != null ||
        widget.filter.hasPassword != null ||
        widget.filter.sortField != null;
  }

  void _clearLoyaltyCardsFilters() {
    _programNameController.clear();
    _issuerController.clear();

    _updateFilter(
      (f) => f.copyWith(
        programName: null,
        issuer: null,
        barcodeType: null,
        hasCardNumber: null,
        hasBarcodeValue: null,
        hasPassword: null,
        sortField: null,
      ),
    );
  }
}
