import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/certificate/certificate_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class CertificatesFilterSection extends StatefulWidget {
  final CertificateFilter filter;
  final Function(CertificateFilter) onFilterChanged;

  const CertificatesFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<CertificatesFilterSection> createState() =>
      _CertificatesFilterSectionState();
}

class _CertificatesFilterSectionState extends State<CertificatesFilterSection> {
  late TextEditingController _issuerController;
  late TextEditingController _subjectController;
  late TextEditingController _serialController;

  @override
  void initState() {
    super.initState();
    _issuerController = TextEditingController(text: widget.filter.issuer);
    _subjectController = TextEditingController(text: widget.filter.subject);
    _serialController = TextEditingController(text: widget.filter.serialNumber);
  }

  @override
  void didUpdateWidget(CertificatesFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _issuerController,
      oldValue: oldWidget.filter.issuer ?? '',
      newValue: widget.filter.issuer ?? '',
    );
    syncTextController(
      controller: _subjectController,
      oldValue: oldWidget.filter.subject ?? '',
      newValue: widget.filter.subject ?? '',
    );
    syncTextController(
      controller: _serialController,
      oldValue: oldWidget.filter.serialNumber ?? '',
      newValue: widget.filter.serialNumber ?? '',
    );
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _subjectController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _updateFilter(CertificateFilter Function(CertificateFilter) updater) {
    widget.onFilterChanged(updater(widget.filter));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.verified_user, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры сертификатов',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasCertificatesSpecificFilters())
                TextButton.icon(
                  onPressed: _clearCertificatesFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Сбросить'),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Текстовые фильтры
        _buildTextFilters(),

        const Divider(height: 1),

        // Форматы и алгоритмы
        _buildFormatAndAlgorithmSection(),

        const Divider(height: 1),

        // Статусные фильтры
        _buildStatusFilters(),

        const Divider(height: 1),

        // Сортировка
        _buildSortingSection(),
      ],
    );
  }

  // ============================================================================
  // Текстовые фильтры
  // ============================================================================

  Widget _buildTextFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поиск по полям',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Issuer
          TextField(
            controller: _issuerController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Издатель (Issuer)',
              hintText: 'Например: Let\'s Encrypt...',
              prefixIcon: const Icon(Icons.business),
              suffixIcon: _issuerController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _issuerController.clear();
                        _updateFilter((f) => f.copyWith(issuer: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(issuer: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Subject
          TextField(
            controller: _subjectController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Субъект (Subject)',
              hintText: 'Например: CN=example.com...',
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: _subjectController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _subjectController.clear();
                        _updateFilter((f) => f.copyWith(subject: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) => f.copyWith(subject: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
          const SizedBox(height: 12),

          // Serial Number
          TextField(
            controller: _serialController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Серийный номер',
              hintText: 'Введите серийный номер...',
              prefixIcon: const Icon(Icons.numbers),
              suffixIcon: _serialController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _serialController.clear();
                        _updateFilter((f) => f.copyWith(serialNumber: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(serialNumber: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Форматы и алгоритмы
  // ============================================================================

  Widget _buildFormatAndAlgorithmSection() {
    return ExpansionTile(
      leading: const Icon(Icons.settings_suggest),
      title: const Text('Параметры сертификата'),
      initiallyExpanded:
          widget.filter.certificateFormat != null ||
          widget.filter.keyAlgorithm != null,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Формат',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CertificateFormat.values.map((format) {
                  return ChoiceChip(
                    label: Text(format.name.toUpperCase()),
                    selected: widget.filter.certificateFormat == format,
                    onSelected: (selected) {
                      _updateFilter(
                        (f) => f.copyWith(
                          certificateFormat: selected ? format : null,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Алгоритм ключа',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CertificateKeyAlgorithm.values.map((algo) {
                  return ChoiceChip(
                    label: Text(algo.name.toUpperCase()),
                    selected: widget.filter.keyAlgorithm == algo,
                    onSelected: (selected) {
                      _updateFilter(
                        (f) => f.copyWith(keyAlgorithm: selected ? algo : null),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Наличие данных'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Приватный ключ',
                value: widget.filter.hasPrivateKey,
                icon: Icons.security,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasPrivateKey: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'PEM (текст)',
                value: widget.filter.hasCertificatePem,
                icon: Icons.text_snippet_outlined,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasCertificatePem: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'Бинарные данные (Blob)',
                value: widget.filter.hasCertificateBlob,
                icon: Icons.data_object,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasCertificateBlob: value));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTriStateCheckbox({
    required String label,
    required bool? value,
    required IconData icon,
    required void Function(bool?) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // Cycle: null -> true -> false -> null
        if (value == null) {
          onChanged(true);
        } else if (value == true) {
          onChanged(false);
        } else {
          onChanged(null);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: value != null
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: value == true
              ? colorScheme.primary.withOpacity(0.1)
              : value == false
              ? colorScheme.error.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value == true
                  ? colorScheme.primary
                  : value == false
                  ? colorScheme.error
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (value != null)
              Icon(
                value ? Icons.check : Icons.close,
                size: 18,
                color: value ? colorScheme.primary : colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveStatusFilters() {
    return widget.filter.hasPrivateKey != null ||
        widget.filter.hasCertificatePem != null ||
        widget.filter.hasCertificateBlob != null;
  }

  // ============================================================================
  // Сортировка
  // ============================================================================

  Widget _buildSortingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сортировка',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip(
                label: 'По названию',
                field: CertificateSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По издателю',
                field: CertificateSortField.issuer,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По субъекту',
                field: CertificateSortField.subject,
                icon: Icons.person_outline,
              ),
              _buildSortChip(
                label: 'По сер. номеру',
                field: CertificateSortField.serialNumber,
                icon: Icons.numbers,
              ),
              _buildSortChip(
                label: 'По дате начала',
                field: CertificateSortField.validFrom,
                icon: Icons.calendar_today,
              ),
              _buildSortChip(
                label: 'По дате окончания',
                field: CertificateSortField.validTo,
                icon: Icons.event_busy,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: CertificateSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: CertificateSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: CertificateSortField.lastUsedAt,
                icon: Icons.access_time,
              ),
            ],
          ),
          if (widget.filter.sortField != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _updateFilter((f) => f.copyWith(sortField: null));
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Сбросить сортировку'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required CertificateSortField field,
    required IconData icon,
  }) {
    final isSelected = widget.filter.sortField == field;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? colorScheme.onSecondaryContainer : null,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(sortField: selected ? field : null));
      },
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
    );
  }

  // ============================================================================
  // Вспомогательные методы
  // ============================================================================

  bool _hasCertificatesSpecificFilters() {
    return widget.filter.issuer != null ||
        widget.filter.subject != null ||
        widget.filter.serialNumber != null ||
        widget.filter.certificateFormat != null ||
        widget.filter.keyAlgorithm != null ||
        widget.filter.hasPrivateKey != null ||
        widget.filter.hasCertificatePem != null ||
        widget.filter.hasCertificateBlob != null ||
        widget.filter.sortField != null;
  }

  void _clearCertificatesFilters() {
    _issuerController.clear();
    _subjectController.clear();
    _serialController.clear();

    _updateFilter(
      (f) => f.copyWith(
        issuer: null,
        subject: null,
        serialNumber: null,
        certificateFormat: null,
        keyAlgorithm: null,
        hasPrivateKey: null,
        hasCertificatePem: null,
        hasCertificateBlob: null,
        sortField: null,
      ),
    );
  }
}
