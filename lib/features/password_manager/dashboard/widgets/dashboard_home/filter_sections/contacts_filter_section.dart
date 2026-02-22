import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class ContactsFilterSection extends StatefulWidget {
  const ContactsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final ContactsFilter filter;
  final ValueChanged<ContactsFilter> onFilterChanged;

  @override
  State<ContactsFilterSection> createState() => _ContactsFilterSectionState();
}

class _ContactsFilterSectionState extends State<ContactsFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _phoneController = TextEditingController(text: widget.filter.phone ?? '');
    _emailController = TextEditingController(text: widget.filter.email ?? '');
    _companyController = TextEditingController(
      text: widget.filter.company ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ContactsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.name != widget.filter.name) {
      _nameController.text = widget.filter.name ?? '';
    }
    if (oldWidget.filter.phone != widget.filter.phone) {
      _phoneController.text = widget.filter.phone ?? '';
    }
    if (oldWidget.filter.email != widget.filter.email) {
      _emailController.text = widget.filter.email ?? '';
    }
    if (oldWidget.filter.company != widget.filter.company) {
      _companyController.text = widget.filter.company ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
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
            labelText: 'Имя',
            hintText: 'Например: Иван Петров',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Телефон',
            hintText: '+7...',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(phone: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Email',
            hintText: 'name@company.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(email: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _companyController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Компания',
            hintText: 'Например: Hoplixi',
            prefixIcon: const Icon(Icons.business_outlined),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(company: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Экстренный контакт'),
              selected: widget.filter.isEmergencyContact == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(
                  isEmergencyContact: selected ? true : null,
                ),
              ),
            ),
            FilterChip(
              label: const Text('С телефоном'),
              selected: widget.filter.hasPhone == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPhone: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Без телефона'),
              selected: widget.filter.hasPhone == false,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPhone: selected ? false : null),
              ),
            ),
            FilterChip(
              label: const Text('С email'),
              selected: widget.filter.hasEmail == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasEmail: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Без email'),
              selected: widget.filter.hasEmail == false,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasEmail: selected ? false : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
