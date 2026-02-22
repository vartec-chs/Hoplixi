import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/filter/index.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class CertificatesFilterSection extends StatefulWidget {
  const CertificatesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final CertificatesFilter filter;
  final ValueChanged<CertificatesFilter> onFilterChanged;

  @override
  State<CertificatesFilterSection> createState() =>
      _CertificatesFilterSectionState();
}

class _CertificatesFilterSectionState extends State<CertificatesFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _issuerController;
  late final TextEditingController _subjectController;
  late final TextEditingController _serialController;
  late final TextEditingController _fingerprintController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _issuerController = TextEditingController(text: widget.filter.issuer ?? '');
    _subjectController = TextEditingController(
      text: widget.filter.subject ?? '',
    );
    _serialController = TextEditingController(
      text: widget.filter.serialNumber ?? '',
    );
    _fingerprintController = TextEditingController(
      text: widget.filter.fingerprint ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _subjectController.dispose();
    _serialController.dispose();
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
            hintText: 'Сертификат сервера',
            prefixIcon: const Icon(Icons.title),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(name: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _issuerController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Issuer',
            hintText: 'Let\'s Encrypt',
            prefixIcon: const Icon(Icons.business),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(issuer: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subjectController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Subject',
            hintText: 'CN=example.com',
            prefixIcon: const Icon(Icons.verified_user),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(subject: v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serialController,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Serial number',
            hintText: '0A12BC...',
            prefixIcon: const Icon(Icons.numbers),
          ),
          onChanged: (v) => widget.onFilterChanged(
            widget.filter.copyWith(
              serialNumber: v.trim().isEmpty ? null : v.trim(),
            ),
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
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Есть private key'),
              selected: widget.filter.hasPrivateKey == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPrivateKey: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Без private key'),
              selected: widget.filter.hasPrivateKey == false,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPrivateKey: selected ? false : null),
              ),
            ),
            FilterChip(
              label: const Text('Есть PFX'),
              selected: widget.filter.hasPfx == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(hasPfx: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Auto-renew'),
              selected: widget.filter.autoRenew == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(autoRenew: selected ? true : null),
              ),
            ),
            FilterChip(
              label: const Text('Истекшие'),
              selected: widget.filter.isExpired == true,
              onSelected: (selected) => widget.onFilterChanged(
                widget.filter.copyWith(isExpired: selected ? true : null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
