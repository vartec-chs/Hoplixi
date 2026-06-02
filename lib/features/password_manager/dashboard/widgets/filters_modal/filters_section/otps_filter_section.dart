import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/vault_db/core/models/filters/filters.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/otp/otp_items.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class OtpsFilterSection extends StatefulWidget {
  final OtpFilter filter;
  final Function(OtpFilter) onFilterChanged;

  const OtpsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<OtpsFilterSection> createState() => _OtpsFilterSectionState();
}

class _OtpsFilterSectionState extends State<OtpsFilterSection> {
  late TextEditingController _issuerController;
  late TextEditingController _accountNameController;
  late TextEditingController _customDigitsController;

  @override
  void initState() {
    super.initState();
    _issuerController = TextEditingController(text: widget.filter.issuer);
    _accountNameController = TextEditingController(
      text: widget.filter.accountName,
    );
    _customDigitsController = TextEditingController(
      text: widget.filter.digits?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(OtpsFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncTextController(
      controller: _issuerController,
      oldValue: oldWidget.filter.issuer ?? '',
      newValue: widget.filter.issuer ?? '',
    );
    syncTextController(
      controller: _accountNameController,
      oldValue: oldWidget.filter.accountName ?? '',
      newValue: widget.filter.accountName ?? '',
    );
    syncTextController(
      controller: _customDigitsController,
      oldValue: oldWidget.filter.digits?.toString() ?? '',
      newValue: widget.filter.digits?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _customDigitsController.dispose();
    super.dispose();
  }

  void _updateFilter(OtpFilter Function(OtpFilter) updater) {
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
              Icon(Icons.security, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Фильтры OTP',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_hasOtpsSpecificFilters())
                TextButton.icon(
                  onPressed: _clearOtpsFilters,
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

        // Типы OTP
        _buildOtpTypesSection(),

        const Divider(height: 1),

        // Алгоритмы
        _buildAlgorithmsSection(),

        const Divider(height: 1),

        // Количество цифр
        _buildDigitsSection(),

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
            'Поиск',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Издатель (Issuer)
          TextField(
            controller: _issuerController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Издатель',
              hintText: 'Например: Google, GitHub...',
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

          // Имя аккаунта
          TextField(
            controller: _accountNameController,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя аккаунта',
              hintText: 'Например: user@example.com',
              prefixIcon: const Icon(Icons.account_circle),
              suffixIcon: _accountNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _accountNameController.clear();
                        _updateFilter((f) => f.copyWith(accountName: null));
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              final trimmed = value.trim();
              _updateFilter(
                (f) =>
                    f.copyWith(accountName: trimmed.isEmpty ? null : trimmed),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Типы OTP
  // ============================================================================

  Widget _buildOtpTypesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тип OTP',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildOtpTypeChip(
                label: 'TOTP',
                type: OtpType.totp,
                icon: Icons.access_time,
              ),
              _buildOtpTypeChip(
                label: 'HOTP',
                type: OtpType.hotp,
                icon: Icons.numbers,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpTypeChip({
    required String label,
    required OtpType type,
    required IconData icon,
  }) {
    final isSelected = widget.filter.type == type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(type: selected ? type : null));
      },
    );
  }

  // ============================================================================
  // Алгоритмы
  // ============================================================================

  Widget _buildAlgorithmsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Алгоритм хеширования',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAlgorithmChip(
                label: 'SHA-1',
                algorithm: OtpHashAlgorithm.SHA1,
              ),
              _buildAlgorithmChip(
                label: 'SHA-256',
                algorithm: OtpHashAlgorithm.SHA256,
              ),
              _buildAlgorithmChip(
                label: 'SHA-512',
                algorithm: OtpHashAlgorithm.SHA512,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmChip({
    required String label,
    required OtpHashAlgorithm algorithm,
  }) {
    final isSelected = widget.filter.algorithm == algorithm;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _updateFilter((f) => f.copyWith(algorithm: selected ? algorithm : null));
      },
    );
  }

  // ============================================================================
  // Количество цифр
  // ============================================================================

  Widget _buildDigitsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Количество цифр',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customDigitsController,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Значение',
                    hintText: 'Например: 6',
                    suffixIcon: _customDigitsController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _customDigitsController.clear();
                              _updateFilter((f) => f.copyWith(digits: null));
                            },
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    _updateFilter((f) => f.copyWith(digits: intValue));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('6'),
                    onPressed: () {
                      _customDigitsController.text = '6';
                      _updateFilter((f) => f.copyWith(digits: 6));
                    },
                  ),
                  ActionChip(
                    label: const Text('8'),
                    onPressed: () {
                      _customDigitsController.text = '8';
                      _updateFilter((f) => f.copyWith(digits: 8));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Наличие полей'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'С издателем',
                value: widget.filter.hasIssuer,
                icon: Icons.business,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasIssuer: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С именем аккаунта',
                value: widget.filter.hasAccountName,
                icon: Icons.account_circle,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasAccountName: value));
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
    return widget.filter.hasIssuer != null ||
        widget.filter.hasAccountName != null;
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
                field: OtpSortField.name,
                icon: Icons.title,
              ),
              _buildSortChip(
                label: 'По издателю',
                field: OtpSortField.issuer,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По аккаунту',
                field: OtpSortField.accountName,
                icon: Icons.account_circle,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: OtpSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: OtpSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: OtpSortField.lastUsedAt,
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
    required OtpSortField field,
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

  bool _hasOtpsSpecificFilters() {
    return widget.filter.issuer != null ||
        widget.filter.accountName != null ||
        widget.filter.type != null ||
        widget.filter.algorithm != null ||
        widget.filter.digits != null ||
        widget.filter.hasIssuer != null ||
        widget.filter.hasAccountName != null ||
        widget.filter.sortField != null;
  }

  void _clearOtpsFilters() {
    _issuerController.clear();
    _accountNameController.clear();
    _customDigitsController.clear();

    _updateFilter(
      (f) => f.copyWith(
        issuer: null,
        accountName: null,
        type: null,
        algorithm: null,
        digits: null,
        hasIssuer: null,
        hasAccountName: null,
        sortField: null,
      ),
    );
  }
}
