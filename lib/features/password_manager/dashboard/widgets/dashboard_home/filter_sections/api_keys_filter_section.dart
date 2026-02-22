import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class ApiKeysFilterSection extends StatefulWidget {
  const ApiKeysFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final ApiKeysFilter filter;
  final ValueChanged<ApiKeysFilter> onFilterChanged;

  @override
  State<ApiKeysFilterSection> createState() => _ApiKeysFilterSectionState();
}

class _ApiKeysFilterSectionState extends State<ApiKeysFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _serviceController;
  late final TextEditingController _tokenTypeController;
  late final TextEditingController _environmentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _serviceController = TextEditingController(
      text: widget.filter.service ?? '',
    );
    _tokenTypeController = TextEditingController(
      text: widget.filter.tokenType ?? '',
    );
    _environmentController = TextEditingController(
      text: widget.filter.environment ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ApiKeysFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.name != widget.filter.name) {
      _nameController.text = widget.filter.name ?? '';
    }
    if (oldWidget.filter.service != widget.filter.service) {
      _serviceController.text = widget.filter.service ?? '';
    }
    if (oldWidget.filter.tokenType != widget.filter.tokenType) {
      _tokenTypeController.text = widget.filter.tokenType ?? '';
    }
    if (oldWidget.filter.environment != widget.filter.environment) {
      _environmentController.text = widget.filter.environment ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceController.dispose();
    _tokenTypeController.dispose();
    _environmentController.dispose();
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
            hintText: 'Например: GitHub API',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serviceController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Сервис',
            hintText: 'github, openai, aws...',
            prefixIcon: const Icon(Icons.cloud_outlined),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(service: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tokenTypeController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Тип токена',
            hintText: 'Bearer, PAT, JWT...',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              tokenType: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _environmentController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Окружение',
            hintText: 'prod, stage, dev...',
            prefixIcon: const Icon(Icons.settings_ethernet),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              environment: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Только отозванные'),
              selected: widget.filter.revoked == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(revoked: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Не отозванные'),
              selected: widget.filter.revoked == false,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(revoked: selected ? false : null),
              ),
            ),
            FilterChip(
              label: const Text('Есть срок действия'),
              selected: widget.filter.hasExpiration == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasExpiration: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Без срока действия'),
              selected: widget.filter.hasExpiration == false,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasExpiration: selected ? false : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
