import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class LicenseKeysFilterSection extends StatefulWidget {
  const LicenseKeysFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final LicenseKeysFilter filter;
  final ValueChanged<LicenseKeysFilter> onFilterChanged;

  @override
  State<LicenseKeysFilterSection> createState() =>
      _LicenseKeysFilterSectionState();
}

class _LicenseKeysFilterSectionState extends State<LicenseKeysFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _productController;
  late final TextEditingController _licenseTypeController;
  late final TextEditingController _orderIdController;
  late final TextEditingController _purchaseFromController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _productController = TextEditingController(
      text: widget.filter.product ?? '',
    );
    _licenseTypeController = TextEditingController(
      text: widget.filter.licenseType ?? '',
    );
    _orderIdController = TextEditingController(
      text: widget.filter.orderId ?? '',
    );
    _purchaseFromController = TextEditingController(
      text: widget.filter.purchaseFrom ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productController.dispose();
    _licenseTypeController.dispose();
    _orderIdController.dispose();
    _purchaseFromController.dispose();
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
            hintText: 'JetBrains License',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _productController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Продукт',
            hintText: 'IntelliJ IDEA Ultimate',
            prefixIcon: const Icon(Icons.apps),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(product: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _licenseTypeController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Тип лицензии',
            hintText: 'subscription | perpetual | trial',
            prefixIcon: const Icon(Icons.sell),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              licenseType: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _orderIdController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Order ID',
            hintText: 'ORDER-12345',
            prefixIcon: const Icon(Icons.receipt_long),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(orderId: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _purchaseFromController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Где куплено',
            hintText: 'JetBrains Store',
            prefixIcon: const Icon(Icons.store),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              purchaseFrom: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilterChip(
          label: const Text('Только истёкшие'),
          selected: widget.filter.expiredOnly == true,
          onSelected: (selected) => widget.onFilterChanged(
            widget.filter.copyWith(expiredOnly: selected ? true : null),
          ),
        ),
      ],
    );
  }
}
