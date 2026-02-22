import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class CryptoWalletsFilterSection extends StatefulWidget {
  const CryptoWalletsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final CryptoWalletsFilter filter;
  final ValueChanged<CryptoWalletsFilter> onFilterChanged;

  @override
  State<CryptoWalletsFilterSection> createState() =>
      _CryptoWalletsFilterSectionState();
}

class _CryptoWalletsFilterSectionState
    extends State<CryptoWalletsFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _walletTypeController;
  late final TextEditingController _networkController;
  late final TextEditingController _hardwareController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _walletTypeController = TextEditingController(
      text: widget.filter.walletType ?? '',
    );
    _networkController = TextEditingController(
      text: widget.filter.network ?? '',
    );
    _hardwareController = TextEditingController(
      text: widget.filter.hardwareDevice ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _walletTypeController.dispose();
    _networkController.dispose();
    _hardwareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Название',
            hintText: 'Main wallet',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _walletTypeController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Тип кошелька',
            hintText: 'seed / private_key / hardware',
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              walletType: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _networkController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Сеть',
            hintText: 'ethereum / bitcoin / solana',
            prefixIcon: const Icon(Icons.hub),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(network: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hardwareController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Аппаратный девайс',
            hintText: 'Ledger / Trezor',
            prefixIcon: const Icon(Icons.usb),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              hardwareDevice: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Watch-only'),
              selected: widget.filter.watchOnly == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(watchOnly: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Есть mnemonic'),
              selected: widget.filter.hasMnemonic == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasMnemonic: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Есть private key'),
              selected: widget.filter.hasPrivateKey == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPrivateKey: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Есть xprv'),
              selected: widget.filter.hasXprv == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasXprv: selected ? true : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
