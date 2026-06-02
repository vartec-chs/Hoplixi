import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/crypto_wallet/crypto_wallet_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class CryptoWalletsFilterSection extends StatefulWidget {
  final CryptoWalletFilter filter;
  final Function(CryptoWalletFilter) onFilterChanged;

  const CryptoWalletsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<CryptoWalletsFilterSection> createState() =>
      _CryptoWalletsFilterSectionState();
}

class _CryptoWalletsFilterSectionState
    extends State<CryptoWalletsFilterSection> {
  late TextEditingController _hardwareController;

  @override
  void initState() {
    super.initState();
    _hardwareController = TextEditingController(text: widget.filter.hardwareDevice);
  }

  @override
  void didUpdateWidget(CryptoWalletsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _hardwareController,
      oldValue: oldWidget.filter.hardwareDevice ?? '',
      newValue: widget.filter.hardwareDevice ?? '',
    );
  }

  @override
  void dispose() {
    _hardwareController.dispose();
    super.dispose();
  }

  void _updateFilter(CryptoWalletFilter Function(CryptoWalletFilter) updater) {
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
              Icon(Icons.account_balance_wallet, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры криптокошельков',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasCryptoWalletsSpecificFilters())
                TextButton.icon(
                  onPressed: _clearCryptoWalletsFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Типы кошельков
        _buildWalletTypeSection(),

        const Divider(height: 1),

        // Сети
        _buildNetworkSection(),

        const Divider(height: 1),

        // Текстовые фильтры (Аппаратное устройство)
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
            'Аппаратное устройство',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _hardwareController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Название устройства',
              hintText: 'Например: Ledger, Trezor...',
              prefixIcon: const Icon(Icons.developer_board),
              suffixIcon: _hardwareController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _hardwareController.clear();
                        _updateFilter((f) => f.copyWith(hardwareDevice: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(hardwareDevice: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы кошельков
  // ============================================================================

  Widget _buildWalletTypeSection() {
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text('Тип кошелька'),
      initiallyExpanded: widget.filter.walletType != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CryptoWalletType.values.map((type) {
              return ChoiceChip(
                label: Text(_getWalletTypeLabel(type)),
                selected: widget.filter.walletType == type,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(walletType: selected ? type : null),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getWalletTypeLabel(CryptoWalletType type) {
    switch (type) {
      case CryptoWalletType.software:
        return 'Программный';
      case CryptoWalletType.hardware:
        return 'Аппаратный';
      case CryptoWalletType.paper:
        return 'Бумажный';
      case CryptoWalletType.watchOnly:
        return 'Только просмотр';
      case CryptoWalletType.multisig:
        return 'Мультисиг';
      case CryptoWalletType.other:
        return 'Другой';
    }
  }

  // ============================================================================
  // Сети
  // ============================================================================

  Widget _buildNetworkSection() {
    return ExpansionTile(
      leading: const Icon(Icons.hub),
      title: const Text('Сеть / Блокчейн'),
      initiallyExpanded: widget.filter.network != null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CryptoNetwork.values.map((net) {
              return ChoiceChip(
                label: Text(net.name.toUpperCase()),
                selected: widget.filter.network == net,
                onSelected: (selected) {
                  _updateFilter(
                    (f) => f.copyWith(network: selected ? net : null),
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
                label: 'Есть мнемоника (seed)',
                value: widget.filter.hasMnemonic,
                icon: Icons.vpn_key,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasMnemonic: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Есть приватный ключ',
                value: widget.filter.hasPrivateKey,
                icon: Icons.lock_outline,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasPrivateKey: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Только для просмотра',
                value: widget.filter.watchOnly,
                icon: Icons.visibility,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(watchOnly: value));
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
    return widget.filter.hasMnemonic != null ||
        widget.filter.hasPrivateKey != null ||
        widget.filter.watchOnly != null;
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
                field: CryptoWalletSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По типу',
                field: CryptoWalletSortField.walletType,
                icon: Icons.category,
              ),
              _buildSortChip(
                label: 'По сети',
                field: CryptoWalletSortField.network,
                icon: Icons.hub,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: CryptoWalletSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: CryptoWalletSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: CryptoWalletSortField.lastUsedAt,
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
    required CryptoWalletSortField field,
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

  bool _hasCryptoWalletsSpecificFilters() {
    return widget.filter.walletType != null ||
        widget.filter.network != null ||
        widget.filter.hardwareDevice != null ||
        widget.filter.watchOnly != null ||
        widget.filter.hasMnemonic != null ||
        widget.filter.hasPrivateKey != null ||
        widget.filter.sortField != null;
  }

  void _clearCryptoWalletsFilters() {
    _hardwareController.clear();

    _updateFilter(
      (f) => f.copyWith(
        walletType: null,
        network: null,
        hardwareDevice: null,
        watchOnly: null,
        hasMnemonic: null,
        hasPrivateKey: null,
        sortField: null,
      ),
    );
  }
}
