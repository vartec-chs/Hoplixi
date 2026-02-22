import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class SshKeysFilterSection extends StatefulWidget {
  const SshKeysFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final SshKeysFilter filter;
  final ValueChanged<SshKeysFilter> onFilterChanged;

  @override
  State<SshKeysFilterSection> createState() => _SshKeysFilterSectionState();
}

class _SshKeysFilterSectionState extends State<SshKeysFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _keyTypeController;
  late final TextEditingController _fingerprintController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _keyTypeController = TextEditingController(
      text: widget.filter.keyType ?? '',
    );
    _fingerprintController = TextEditingController(
      text: widget.filter.fingerprint ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyTypeController.dispose();
    _fingerprintController.dispose();
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
            hintText: 'Ключ для сервера',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyTypeController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Тип ключа',
            hintText: 'ed25519, rsa...',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(keyType: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fingerprintController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Fingerprint',
            hintText: 'SHA256:...',
            prefixIcon: const Icon(Icons.fingerprint),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              fingerprint: v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Добавлен в ssh-agent'),
              selected: widget.filter.addedToAgent == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(addedToAgent: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Не добавлен в ssh-agent'),
              selected: widget.filter.addedToAgent == false,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(addedToAgent: selected ? false : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
