import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class IdentitiesFilterSection extends StatefulWidget {
  const IdentitiesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final IdentitiesFilter filter;
  final ValueChanged<IdentitiesFilter> onFilterChanged;

  @override
  State<IdentitiesFilterSection> createState() =>
      _IdentitiesFilterSectionState();
}

class _IdentitiesFilterSectionState extends State<IdentitiesFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _idTypeController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _nationalityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _idTypeController = TextEditingController(text: widget.filter.idType ?? '');
    _idNumberController = TextEditingController(
      text: widget.filter.idNumber ?? '',
    );
    _fullNameController = TextEditingController(
      text: widget.filter.fullName ?? '',
    );
    _nationalityController = TextEditingController(
      text: widget.filter.nationality ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    _fullNameController.dispose();
    _nationalityController.dispose();
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
            hintText: 'Паспорт РФ',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _idTypeController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Тип документа',
            hintText: 'passport / id_card / drivers_license',
            prefixIcon: const Icon(Icons.badge),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(idType: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _idNumberController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Номер документа',
            hintText: '1234 567890',
            prefixIcon: const Icon(Icons.pin),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              idNumber: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fullNameController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'ФИО',
            hintText: 'Иванов Иван Иванович',
            prefixIcon: const Icon(Icons.person),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              fullName: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nationalityController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Гражданство',
            hintText: 'RU',
            prefixIcon: const Icon(Icons.flag),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              nationality: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Только верифицированные'),
              selected: widget.filter.verified == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(verified: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Только просроченные'),
              selected: widget.filter.expiredOnly == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(expiredOnly: selected ? true : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
