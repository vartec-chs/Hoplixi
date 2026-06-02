import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/bank_card/bank_card_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class BankCardsFilterSection extends StatefulWidget {
  final BankCardFilter filter;
  final Function(BankCardFilter) onFilterChanged;

  const BankCardsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<BankCardsFilterSection> createState() => _BankCardsFilterSectionState();
}

class _BankCardsFilterSectionState extends State<BankCardsFilterSection> {
  late TextEditingController _bankNameController;
  late TextEditingController _cardholderNameController;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(text: widget.filter.bankName);
    _cardholderNameController = TextEditingController(
      text: widget.filter.cardholderName,
    );
  }

  @override
  void didUpdateWidget(BankCardsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _bankNameController,
      oldValue: oldWidget.filter.bankName ?? '',
      newValue: widget.filter.bankName ?? '',
    );
    syncTextController(
      controller: _cardholderNameController,
      oldValue: oldWidget.filter.cardholderName ?? '',
      newValue: widget.filter.cardholderName ?? '',
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  void _updateFilter(BankCardFilter Function(BankCardFilter) updater) {
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
              Icon(Icons.credit_card, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры банковских карт',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasBankCardsSpecificFilters())
                TextButton.icon(
                  onPressed: _clearBankCardsFilters,
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

        // Типы карт
        _buildCardTypesSection(),

        const Divider(height: 1),

        // Платежные системы
        _buildCardNetworksSection(),

        const Divider(height: 1),

        // Срок действия
        _buildExpirySection(),

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

          // Название банка
          TextField(
            controller: _bankNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название банка',
              hintText: 'Например: Сбербанк, Тинькофф...',
              prefixIcon: const Icon(Icons.account_balance),
              suffixIcon: _bankNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _bankNameController.clear();
                        _updateFilter((f) => f.copyWith(bankName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(bankName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Имя держателя карты
          TextField(
            controller: _cardholderNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя держателя карты',
              hintText: 'Например: IVAN IVANOV',
              prefixIcon: const Icon(Icons.person),
              suffixIcon: _cardholderNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _cardholderNameController.clear();
                        _updateFilter((f) => f.copyWith(cardholderName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(
                  cardholderName: trimmed.isEmpty ? null : trimmed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы карт
  // ============================================================================

  Widget _buildCardTypesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип карты',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CardType.values.map((type) {
              return _buildCardTypeChip(
                label: _getCardTypeLabel(type),
                type: type,
                icon: _getCardTypeIcon(type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getCardTypeLabel(CardType type) {
    switch (type) {
      case CardType.debit:
        return 'Дебетовая';
      case CardType.credit:
        return 'Кредитная';
      case CardType.prepaid:
        return 'Предоплаченная';
      case CardType.virtual:
        return 'Виртуальная';
      case CardType.other:
        return 'Другая';
    }
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.debit:
        return Icons.account_balance_wallet;
      case CardType.credit:
        return Icons.credit_score;
      case CardType.prepaid:
        return Icons.payment;
      case CardType.virtual:
        return Icons.credit_card_off;
      case CardType.other:
        return Icons.more_horiz;
    }
  }

  Widget _buildCardTypeChip({
    required String label,
    required CardType type,
    required IconData icon,
  }) {
    final isSelected = widget.filter.cardType == type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(cardType: selected ? type : null));
      },
    );
  }

  // ============================================================================
  // Платежные системы
  // ============================================================================

  Widget _buildCardNetworksSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Платежная система',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CardNetwork.values.map((network) {
              return _buildCardNetworkChip(
                label: network.name.toUpperCase(),
                network: network,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardNetworkChip({
    required String label,
    required CardNetwork network,
  }) {
    final isSelected = widget.filter.cardNetwork == network;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(cardNetwork: selected ? network : null));
      },
    );
  }

  // ============================================================================
  // Срок действия
  // ============================================================================

  Widget _buildExpirySection() {
    return ExpansionTile(
      leading: const Icon(Icons.event),
      title: const Text('Срок действия'),
      initiallyExpanded: widget.filter.hasExpiry != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Есть срок действия',
                value: widget.filter.hasExpiry,
                icon: Icons.calendar_today,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasExpiry: value));
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
                field: BankCardSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По держателю',
                field: BankCardSortField.cardholderName,
                icon: Icons.person,
              ),
              _buildSortChip(
                label: 'По банку',
                field: BankCardSortField.bankName,
                icon: Icons.account_balance,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: BankCardSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: BankCardSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: BankCardSortField.lastUsedAt,
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
    required BankCardSortField field,
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

  bool _hasBankCardsSpecificFilters() {
    return widget.filter.bankName != null ||
        widget.filter.cardholderName != null ||
        widget.filter.cardType != null ||
        widget.filter.cardNetwork != null ||
        widget.filter.hasExpiry != null ||
        widget.filter.sortField != null;
  }

  void _clearBankCardsFilters() {
    _bankNameController.clear();
    _cardholderNameController.clear();

    _updateFilter(
      (f) => f.copyWith(
        bankName: null,
        cardholderName: null,
        cardType: null,
        cardNetwork: null,
        hasExpiry: null,
        sortField: null,
      ),
    );
  }
}
