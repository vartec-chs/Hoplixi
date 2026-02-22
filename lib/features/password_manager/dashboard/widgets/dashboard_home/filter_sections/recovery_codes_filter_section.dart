import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class RecoveryCodesFilterSection extends StatefulWidget {
  const RecoveryCodesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final RecoveryCodesFilter filter;
  final ValueChanged<RecoveryCodesFilter> onFilterChanged;

  @override
  State<RecoveryCodesFilterSection> createState() =>
      _RecoveryCodesFilterSectionState();
}

class _RecoveryCodesFilterSectionState
    extends State<RecoveryCodesFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _displayHintController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _displayHintController = TextEditingController(
      text: widget.filter.displayHint ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayHintController.dispose();
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
            hintText: 'Backup codes for GitHub',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _displayHintController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Подсказка отображения',
            hintText: 'Показывать последние 2 символа',
            prefixIcon: const Icon(Icons.visibility),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              displayHint: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Одноразовые'),
              selected: widget.filter.oneTime == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(oneTime: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Полностью использованы'),
              selected: widget.filter.depletedOnly == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(depletedOnly: selected ? true : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
