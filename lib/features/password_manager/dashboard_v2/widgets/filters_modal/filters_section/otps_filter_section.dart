import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/main_db/core/models/filter/index.dart';
import 'package:hoplixi/main_db/core/models/enums/index.dart';
import 'controller_sync.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class OtpsFilterSection extends StatefulWidget {
  final OtpsFilter filter;
  final Function(OtpsFilter) onFilterChanged;

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
  late TextEditingController _customPeriodController;

  @override
  void initState() {
    super.initState();
    _issuerController = TextEditingController(text: widget.filter.issuer);
    _accountNameController = TextEditingController(
      text: widget.filter.accountName,
    );
    _customDigitsController = TextEditingController();
    _customPeriodController = TextEditingController();
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
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _customDigitsController.dispose();
    _customPeriodController.dispose();
    super.dispose();
  }

  void _updateFilter(OtpsFilter Function(OtpsFilter) updater) {
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

        // Кодирование секрета
        _buildSecretEncodingSection(),

        const Divider(height: 1),

        // Количество цифр
        _buildDigitsSection(),

        const Divider(height: 1),

        // Периоды
        _buildPeriodsSection(),

        const Divider(height: 1),

        // Статусные фильтры
        _buildStatusFilters(),

        const Divider(height: 1),

        // Пресеты
        _buildPresetsSection(),

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
    return ExpansionTile(
      leading: const Icon(Icons.category),
      title: const Text('Типы OTP'),
      subtitle: widget.filter.types.isNotEmpty
          ? Text(
              '${widget.filter.types.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.types.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildOtpTypeChip(
                label: 'TOTP (Time-based)',
                type: OtpType.totp,
                icon: Icons.access_time,
              ),
              _buildOtpTypeChip(
                label: 'HOTP (Counter-based)',
                type: OtpType.hotp,
                icon: Icons.numbers,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpTypeChip({
    required String label,
    required OtpType type,
    required IconData icon,
  }) {
    final isSelected = widget.filter.types.contains(type);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter((f) => f.copyWith(types: [...f.types, type]));
        } else {
          _updateFilter(
            (f) => f.copyWith(types: f.types.where((t) => t != type).toList()),
          );
        }
      },
    );
  }

  // ============================================================================
  // Алгоритмы
  // ============================================================================

  Widget _buildAlgorithmsSection() {
    return ExpansionTile(
      leading: const Icon(Icons.lock_clock),
      title: const Text('Алгоритмы хеширования'),
      subtitle: widget.filter.algorithms.isNotEmpty
          ? Text(
              '${widget.filter.algorithms.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.algorithms.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAlgorithmChip(label: 'SHA-1', algorithm: AlgorithmOtp.SHA1),
              _buildAlgorithmChip(
                label: 'SHA-256',
                algorithm: AlgorithmOtp.SHA256,
              ),
              _buildAlgorithmChip(
                label: 'SHA-512',
                algorithm: AlgorithmOtp.SHA512,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmChip({
    required String label,
    required AlgorithmOtp algorithm,
  }) {
    final isSelected = widget.filter.algorithms.contains(algorithm);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(
            (f) => f.copyWith(algorithms: [...f.algorithms, algorithm]),
          );
        } else {
          _updateFilter(
            (f) => f.copyWith(
              algorithms: f.algorithms.where((a) => a != algorithm).toList(),
            ),
          );
        }
      },
    );
  }

  // ============================================================================
  // Кодирование секрета
  // ============================================================================

  Widget _buildSecretEncodingSection() {
    return ExpansionTile(
      leading: const Icon(Icons.code),
      title: const Text('Кодирование секрета'),
      subtitle: widget.filter.secretEncodings.isNotEmpty
          ? Text(
              '${widget.filter.secretEncodings.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.secretEncodings.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEncodingChip(
                label: 'BASE32',
                encoding: SecretEncoding.BASE32,
              ),
              _buildEncodingChip(label: 'HEX', encoding: SecretEncoding.HEX),
              _buildEncodingChip(
                label: 'BINARY',
                encoding: SecretEncoding.BINARY,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEncodingChip({
    required String label,
    required SecretEncoding encoding,
  }) {
    final isSelected = widget.filter.secretEncodings.contains(encoding);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(
            (f) =>
                f.copyWith(secretEncodings: [...f.secretEncodings, encoding]),
          );
        } else {
          _updateFilter(
            (f) => f.copyWith(
              secretEncodings: f.secretEncodings
                  .where((e) => e != encoding)
                  .toList(),
            ),
          );
        }
      },
    );
  }

  // ============================================================================
  // Количество цифр
  // ============================================================================

  Widget _buildDigitsSection() {
    return ExpansionTile(
      leading: const Icon(Icons.pin),
      title: const Text('Количество цифр'),
      subtitle: widget.filter.digits.isNotEmpty
          ? Text(
              '${widget.filter.digits.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.digits.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDigitsChip(digits: 6),
                  _buildDigitsChip(digits: 8),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customDigitsController,
                      decoration: const InputDecoration(
                        labelText: 'Другое значение',
                        hintText: 'Например: 7',
                        border: OutlineInputBorder(),
                        errorText: null,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final value = int.tryParse(_customDigitsController.text);
                      if (value != null && value > 0 && value <= 10) {
                        if (!widget.filter.digits.contains(value)) {
                          _updateFilter(
                            (f) => f.copyWith(digits: [...f.digits, value]),
                          );
                          _customDigitsController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Значение $value уже добавлено'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              if (!widget.filter.isValidDigits) ...[
                const SizedBox(height: 8),
                Text(
                  'Внимание: стандартные значения - 6 или 8 цифр',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitsChip({required int digits}) {
    final isSelected = widget.filter.digits.contains(digits);

    return FilterChip(
      label: Text('$digits цифр'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter((f) => f.copyWith(digits: [...f.digits, digits]));
        } else {
          _updateFilter(
            (f) =>
                f.copyWith(digits: f.digits.where((d) => d != digits).toList()),
          );
        }
      },
    );
  }

  // ============================================================================
  // Периоды
  // ============================================================================

  Widget _buildPeriodsSection() {
    return ExpansionTile(
      leading: const Icon(Icons.timer),
      title: const Text('Период обновления (TOTP)'),
      subtitle: widget.filter.periods.isNotEmpty
          ? Text(
              '${widget.filter.periods.length} выбрано',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      initiallyExpanded: widget.filter.periods.isNotEmpty,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodChip(period: 30, label: '30 сек'),
                  _buildPeriodChip(period: 60, label: '60 сек'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPeriodController,
                      decoration: const InputDecoration(
                        labelText: 'Другой период (сек)',
                        hintText: 'От 1 до 300',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final value = int.tryParse(_customPeriodController.text);
                      if (value != null && value > 0 && value <= 300) {
                        if (!widget.filter.periods.contains(value)) {
                          _updateFilter(
                            (f) => f.copyWith(periods: [...f.periods, value]),
                          );
                          _customPeriodController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Период $value сек уже добавлен'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              if (!widget.filter.isValidPeriod) ...[
                const SizedBox(height: 8),
                Text(
                  'Внимание: период должен быть от 1 до 300 секунд',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip({required int period, required String label}) {
    final isSelected = widget.filter.periods.contains(period);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateFilter((f) => f.copyWith(periods: [...f.periods, period]));
        } else {
          _updateFilter(
            (f) => f.copyWith(
              periods: f.periods.where((p) => p != period).toList(),
            ),
          );
        }
      },
    );
  }

  // ============================================================================
  // Статусные фильтры
  // ============================================================================

  Widget _buildStatusFilters() {
    return ExpansionTile(
      leading: const Icon(Icons.check_circle_outline),
      title: const Text('Дополнительные поля'),
      initiallyExpanded: _hasActiveStatusFilters(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTriStateCheckbox(
                label: 'Со связью с паролем',
                value: widget.filter.hasPasswordLink,
                icon: Icons.link,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasPasswordLink: value));
                },
              ),
              const SizedBox(height: 8),
              _buildTriStateCheckbox(
                label: 'С заметками',
                value: widget.filter.hasNotes,
                icon: Icons.note,
                onChanged: (value) {
                  _updateFilter((f) => f.copyWith(hasNotes: value));
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
    return widget.filter.hasPasswordLink != null ||
        widget.filter.hasNotes != null;
  }

  // ============================================================================
  // Пресеты
  // ============================================================================

  Widget _buildPresetsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрые пресеты',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Стандартный TOTP'),
                avatar: const Icon(Icons.access_time, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(
                      types: [OtpType.totp],
                      algorithms: [AlgorithmOtp.SHA1],
                      digits: [6],
                      periods: [30],
                      secretEncodings: [SecretEncoding.BASE32],
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Стандартный HOTP'),
                avatar: const Icon(Icons.numbers, size: 18),
                onPressed: () {
                  _updateFilter(
                    (f) => f.copyWith(
                      types: [OtpType.hotp],
                      algorithms: [AlgorithmOtp.SHA1],
                      digits: [6],
                      secretEncodings: [SecretEncoding.BASE32],
                    ),
                  );
                },
              ),
              ActionChip(
                label: const Text('Все TOTP'),
                avatar: const Icon(Icons.access_time, size: 18),
                onPressed: () {
                  _updateFilter((f) => f.copyWith(types: [OtpType.totp]));
                },
              ),
              ActionChip(
                label: const Text('Все HOTP'),
                avatar: const Icon(Icons.numbers, size: 18),
                onPressed: () {
                  _updateFilter((f) => f.copyWith(types: [OtpType.hotp]));
                },
              ),
            ],
          ),
        ],
      ),
    );
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
                label: 'По издателю',
                field: OtpsSortField.issuer,
                icon: Icons.business,
              ),
              _buildSortChip(
                label: 'По аккаунту',
                field: OtpsSortField.accountName,
                icon: Icons.account_circle,
              ),
              _buildSortChip(
                label: 'По типу',
                field: OtpsSortField.type,
                icon: Icons.category,
              ),
              _buildSortChip(
                label: 'По алгоритму',
                field: OtpsSortField.algorithm,
                icon: Icons.lock_clock,
              ),
              _buildSortChip(
                label: 'По цифрам',
                field: OtpsSortField.digits,
                icon: Icons.pin,
              ),
              _buildSortChip(
                label: 'По периоду',
                field: OtpsSortField.period,
                icon: Icons.timer,
              ),
              _buildSortChip(
                label: 'По дате создания',
                field: OtpsSortField.createdAt,
                icon: Icons.create,
              ),
              _buildSortChip(
                label: 'По дате изменения',
                field: OtpsSortField.modifiedAt,
                icon: Icons.edit,
              ),
              _buildSortChip(
                label: 'По дате доступа',
                field: OtpsSortField.lastAccessed,
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
    required OtpsSortField field,
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
        widget.filter.types.isNotEmpty ||
        widget.filter.algorithms.isNotEmpty ||
        widget.filter.secretEncodings.isNotEmpty ||
        widget.filter.digits.isNotEmpty ||
        widget.filter.periods.isNotEmpty ||
        widget.filter.hasPasswordLink != null ||
        widget.filter.hasNotes != null ||
        widget.filter.sortField != null;
  }

  void _clearOtpsFilters() {
    _issuerController.clear();
    _accountNameController.clear();
    _customDigitsController.clear();
    _customPeriodController.clear();

    _updateFilter(
      (f) => f.copyWith(
        issuer: null,
        accountName: null,
        types: [],
        algorithms: [],
        secretEncodings: [],
        digits: [],
        periods: [],
        hasPasswordLink: null,
        hasNotes: null,
        sortField: null,
      ),
    );
  }
}
