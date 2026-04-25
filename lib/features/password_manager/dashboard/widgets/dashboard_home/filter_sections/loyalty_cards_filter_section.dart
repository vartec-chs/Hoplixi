import 'package:flutter/material.dart';
import 'package:hoplixi/db_core/old/models/filter/loyalty_cards_filter.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_home/filter_sections/controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class LoyaltyCardsFilterSection extends StatefulWidget {
  const LoyaltyCardsFilterSection({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final LoyaltyCardsFilter filter;
  final ValueChanged<LoyaltyCardsFilter> onChanged;

  @override
  State<LoyaltyCardsFilterSection> createState() =>
      _LoyaltyCardsFilterSectionState();
}

class _LoyaltyCardsFilterSectionState extends State<LoyaltyCardsFilterSection> {
  late final TextEditingController _programNameController;
  late final TextEditingController _holderNameController;
  late final TextEditingController _tierController;

  @override
  void initState() {
    super.initState();
    _programNameController = TextEditingController(
      text: widget.filter.programName ?? '',
    );
    _holderNameController = TextEditingController(
      text: widget.filter.holderName ?? '',
    );
    _tierController = TextEditingController(text: widget.filter.tier ?? '');
  }

  @override
  void didUpdateWidget(covariant LoyaltyCardsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _programNameController,
      oldValue: oldWidget.filter.programName ?? '',
      newValue: widget.filter.programName ?? '',
    );
    syncTextController(
      controller: _holderNameController,
      oldValue: oldWidget.filter.holderName ?? '',
      newValue: widget.filter.holderName ?? '',
    );
    syncTextController(
      controller: _tierController,
      oldValue: oldWidget.filter.tier ?? '',
      newValue: widget.filter.tier ?? '',
    );
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _holderNameController.dispose();
    _tierController.dispose();
    super.dispose();
  }

  void _update(LoyaltyCardsFilter Function(LoyaltyCardsFilter) transform) {
    widget.onChanged(transform(widget.filter));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильтры карт лояльности',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _programNameController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Программа',
            hintText: 'Например: Пятерочка Клуб',
            prefixIcon: const Icon(Icons.storefront_outlined),
          ),
          onChanged: (value) {
            final normalized = value.trim();
            _update(
              (f) => f.copyWith(
                programName: normalized.isEmpty ? null : normalized,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _holderNameController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Владелец',
            hintText: 'Имя владельца',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onChanged: (value) {
            final normalized = value.trim();
            _update(
              (f) => f.copyWith(
                holderName: normalized.isEmpty ? null : normalized,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tierController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Уровень',
            hintText: 'Gold, Silver, VIP',
            prefixIcon: const Icon(Icons.workspace_premium_outlined),
          ),
          onChanged: (value) {
            final normalized = value.trim();
            _update(
              (f) => f.copyWith(tier: normalized.isEmpty ? null : normalized),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Есть штрихкод'),
              selected: widget.filter.hasBarcode == true,
              onSelected: (selected) {
                _update((f) => f.copyWith(hasBarcode: selected ? true : null));
              },
            ),
            FilterChip(
              label: const Text('Срок истёк'),
              selected: widget.filter.hasExpiryDatePassed == true,
              onSelected: (selected) {
                _update(
                  (f) =>
                      f.copyWith(hasExpiryDatePassed: selected ? true : null),
                );
              },
            ),
            FilterChip(
              label: const Text('Истекает скоро'),
              selected: widget.filter.isExpiringSoon == true,
              onSelected: (selected) {
                _update(
                  (f) => f.copyWith(isExpiringSoon: selected ? true : null),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _sortChip(context, 'По названию', LoyaltyCardsSortField.name),
            _sortChip(
              context,
              'По программе',
              LoyaltyCardsSortField.programName,
            ),
            _sortChip(
              context,
              'По владельцу',
              LoyaltyCardsSortField.holderName,
            ),
            _sortChip(context, 'По уровню', LoyaltyCardsSortField.tier),
            _sortChip(context, 'По сроку', LoyaltyCardsSortField.expiryDate),
          ],
        ),
      ],
    );
  }

  Widget _sortChip(
    BuildContext context,
    String label,
    LoyaltyCardsSortField field,
  ) {
    return FilterChip(
      label: Text(label),
      selected: widget.filter.sortField == field,
      onSelected: (selected) {
        _update((f) => f.copyWith(sortField: selected ? field : null));
      },
    );
  }
}
