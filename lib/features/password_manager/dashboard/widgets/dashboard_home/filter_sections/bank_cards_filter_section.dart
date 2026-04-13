import 'package:flutter/material.dart';
import 'package:hoplixi/db_core/models/filter/index.dart';
import 'package:hoplixi/db_core/models/enums/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/filter_sections/controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class BankCardsFilterSection extends StatefulWidget {
  final BankCardsFilter filter;
  final Function(BankCardsFilter) onFilterChanged;

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

  void _updateFilter(BankCardsFilter Function(BankCardsFilter) updater) {
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
        _buildExpiryFilters(),

        const Divider(height: 1),

        // Пресеты
        _buildPresetsSection(),

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
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text('Типы карт'),
      subtitle: widget.filter.cardTypes.isNotEmpty
          ? Text(
              '${widget.filter.cardTypes.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.cardTypes.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCardTypeChip(
                label: 'Дебетовая',
                type: CardType.debit,
                icon: Icons.account_balance_wallet,
              ),
              _buildCardTypeChip(
                label: 'Кредитная',
                type: CardType.credit,
                icon: Icons.credit_score,
              ),
              _buildCardTypeChip(
                label: 'Предоплаченная',
                type: CardType.prepaid,
                icon: Icons.payment,
              ),
              _buildCardTypeChip(
                label: 'Виртуальная',
                type: CardType.virtual,
                icon: Icons.credit_card_off,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardTypeChip({
    required String label,
    required CardType type,
    required IconData icon,
  }) {
    final isSelected = widget.filter.cardTypes.contains(type);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter((f) => f.copyWith(cardTypes: [...f.cardTypes, type]));
        } else {
          _updateFilter(
            (f) => f.copyWith(
              cardTypes: f.cardTypes.where((t) => t != type).toList(),
            ),
          );
        }
      },
    );
  }

  // ============================================================================
  // Платежные системы
  // ============================================================================

  Widget _buildCardNetworksSection() {
    return ExpansionTile(
      leading: const Icon(Icons.credit_card),
      title: const Text('Платежные системы'),
      subtitle: widget.filter.cardNetworks.isNotEmpty
          ? Text(
              '${widget.filter.cardNetworks.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.cardNetworks.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Популярные',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCardNetworkChip(
                    label: 'Visa',
                    network: CardNetwork.visa,
                  ),
                  _buildCardNetworkChip(
                    label: 'Mastercard',
                    network: CardNetwork.mastercard,
                  ),
                  _buildCardNetworkChip(
                    label: 'American Express',
                    network: CardNetwork.amex,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Другие',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCardNetworkChip(
                    label: 'Discover',
                    network: CardNetwork.discover,
                  ),
                  _buildCardNetworkChip(
                    label: 'Diners Club',
                    network: CardNetwork.dinersclub,
                  ),
                  _buildCardNetworkChip(label: 'JCB', network: CardNetwork.jcb),
                  _buildCardNetworkChip(
                    label: 'UnionPay',
                    network: CardNetwork.unionpay,
                  ),
                  _buildCardNetworkChip(
                    label: 'Другая',
                    network: CardNetwork.other,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardNetworkChip({
    required String label,
    required CardNetwork network,
  }) {
    final isSelected = widget.filter.cardNetworks.contains(network);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(
            (f) => f.copyWith(cardNetworks: [...f.cardNetworks, network]),
          );
        } else {
          _updateFilter(
            (f) => f.copyWith(
              cardNetworks: f.cardNetworks.where((n) => n != network).toList(),
            ),
          );
        }
      },
    );
  }

  // ============================================================================
  // Фильтры срока действия
  // ============================================================================

  Widget _buildExpiryFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.event),
      title: const Text('Срок действия'),
      initiallyExpanded: _hasActiveExpiryFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Срок истёк',
                value: widget.filter.hasExpiryDatePassed,
                icon: Icons.event_busy,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasExpiryDatePassed: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Истекает скоро (3 месяца)',
                value: widget.filter.isExpiringSoon,
                icon: Icons.warning,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(isExpiringSoon: value));
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

  bool _hasActiveExpiryFilters() {
    return widget.filter.hasExpiryDatePassed != null ||
        widget.filter.isExpiringSoon != null;
  }

  // ============================================================================
  // Пресеты
  // ============================================================================

  Widget _buildPresetsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрые пресеты',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Проблемные карты'),
                avatar: const Icon(Icons.warning, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(
                      hasExpiryDatePassed: true,
                      isExpiringSoon: true,
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Активные карты'),
                avatar: const Icon(Icons.check_circle, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(
                      hasExpiryDatePassed: false,
                      isExpiringSoon: false,
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Дебетовые карты'),
                avatar: const Icon(Icons.account_balance_wallet, size: 18),
                onPressed: () {
                  _updateFilter((f) => f.copyWith(cardTypes: [CardType.debit]));
                },
              ),
              ActionChip(
                label: const Text('Кредитные карты'),
                avatar: const Icon(Icons.credit_score, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(cardTypes: [CardType.credit]),
                  );
                },
              ),
              ActionChip(
                label: const Text('Виртуальные карты'),
                avatar: const Icon(Icons.credit_card_off, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(cardTypes: [CardType.virtual]),
                  );
                },
              ),
              ActionChip(
                label: const Text('Visa & Mastercard'),
                avatar: const Icon(Icons.credit_card, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(
                      cardNetworks: [CardNetwork.visa, CardNetwork.mastercard],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
                field: BankCardsSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По держателю',
                field: BankCardsSortField.cardholderName,
                icon: Icons.person,
              ),
              _buildSortChip(
                label: 'По банку',
                field: BankCardsSortField.bankName,
                icon: Icons.account_balance,
              ),
              _buildSortChip(
                label: 'По сроку действия',
                field: BankCardsSortField.expiryDate,
                icon: Icons.event,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: BankCardsSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: BankCardsSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: BankCardsSortField.lastAccessed,
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
    required BankCardsSortField field,
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
        widget.filter.cardTypes.isNotEmpty ||
        widget.filter.cardNetworks.isNotEmpty ||
        widget.filter.hasExpiryDatePassed != null ||
        widget.filter.isExpiringSoon != null ||
        widget.filter.sortField != null;
  }

  void _clearBankCardsFilters() {
    _bankNameController.clear();
    _cardholderNameController.clear();

    _updateFilter(
      (f) => f.copyWith(
        bankName: null,
        cardholderName: null,
        cardTypes: [],
        cardNetworks: [],
        hasExpiryDatePassed: null,
        isExpiringSoon: null,
        sortField: null,
      ),
    );
  }
}
