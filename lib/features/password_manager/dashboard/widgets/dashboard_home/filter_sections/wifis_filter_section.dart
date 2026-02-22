import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class WifisFilterSection extends StatefulWidget {
  const WifisFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final WifisFilter filter;
  final ValueChanged<WifisFilter> onFilterChanged;

  @override
  State<WifisFilterSection> createState() => _WifisFilterSectionState();
}

class _WifisFilterSectionState extends State<WifisFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _ssidController;
  late final TextEditingController _securityController;
  late final TextEditingController _eapController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _ssidController = TextEditingController(text: widget.filter.ssid ?? '');
    _securityController = TextEditingController(
      text: widget.filter.security ?? '',
    );
    _eapController = TextEditingController(text: widget.filter.eapMethod ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ssidController.dispose();
    _securityController.dispose();
    _eapController.dispose();
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
            hintText: 'Домашняя сеть',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ssidController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'SSID',
            hintText: 'MyWiFi',
            prefixIcon: const Icon(Icons.wifi),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(ssid: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _securityController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Security',
            hintText: 'WPA2 / WPA3 / Open',
            prefixIcon: const Icon(Icons.security),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              security: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _eapController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'EAP method',
            hintText: 'PEAP / TLS',
            prefixIcon: const Icon(Icons.badge),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              eapMethod: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Скрытая сеть'),
              selected: widget.filter.hidden == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hidden: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Есть пароль'),
              selected: widget.filter.hasPassword == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPassword: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Открытая сеть'),
              selected: widget.filter.isOpenNetwork == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(isOpenNetwork: selected ? true : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
