import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/db_core/models/enums/entity_types.dart';
import 'package:hoplixi/shared/custom_fields/models/custom_field_entry.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Редактор кастомных полей — переиспользуемый виджет для любых форм сущностей.
///
/// Принимает список [fields] и вызывает [onChanged] при любом изменении.
/// Полностью stateless с точки зрения родителя — всё состояние хранится в провайдере.
class CustomFieldsEditor extends StatelessWidget {
  const CustomFieldsEditor({
    super.key,
    required this.fields,
    required this.onChanged,
  });

  final List<CustomFieldEntry> fields;
  final ValueChanged<List<CustomFieldEntry>> onChanged;

  void _addField() {
    onChanged([
      ...fields,
      const CustomFieldEntry(label: '', fieldType: CustomFieldType.text),
    ]);
  }

  void _removeField(int index) {
    final list = List<CustomFieldEntry>.from(fields)..removeAt(index);
    onChanged(list);
  }

  void _updateField(int index, CustomFieldEntry updated) {
    final list = List<CustomFieldEntry>.from(fields)..[index] = updated;
    onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Кастомные поля', style: theme.textTheme.titleSmall),
          ],
        ),
        if (fields.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...fields.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CustomFieldRow(
                key: ValueKey('field_${e.key}_${e.value.id}'),
                entry: e.value,
                onChanged: (updated) => _updateField(e.key, updated),
                onRemove: () => _removeField(e.key),
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _addField,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Добавить поле'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Строка одного кастомного поля
// ─────────────────────────────────────────────────────────────────────────────

class _CustomFieldRow extends StatefulWidget {
  const _CustomFieldRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final CustomFieldEntry entry;
  final ValueChanged<CustomFieldEntry> onChanged;
  final VoidCallback onRemove;

  @override
  State<_CustomFieldRow> createState() => _CustomFieldRowState();
}

class _CustomFieldRowState extends State<_CustomFieldRow> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _valueCtrl;
  late final FocusNode _phoneFocusNode;
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'US');
  String? _pendingPhoneValue;

  static final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.entry.label);
    _valueCtrl = TextEditingController(text: widget.entry.value ?? '');
    _phoneFocusNode = FocusNode()..addListener(_handlePhoneFocusChange);
    _pendingPhoneValue = widget.entry.value;
    _syncPhoneNumberState(widget.entry.value);
  }

  @override
  void didUpdateWidget(_CustomFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_labelCtrl.text != widget.entry.label) {
      _labelCtrl.text = widget.entry.label;
    }
    final expectedValue = widget.entry.value ?? '';
    final shouldSyncValueController =
        widget.entry.fieldType != CustomFieldType.phone ||
        oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.fieldType != widget.entry.fieldType;
    if (shouldSyncValueController && _valueCtrl.text != expectedValue) {
      _valueCtrl.text = expectedValue;
    }
    if (oldWidget.entry.fieldType != CustomFieldType.phone &&
        oldWidget.entry.value != widget.entry.value) {
      _pendingPhoneValue = widget.entry.value;
    }
    final shouldResyncPhoneMetadata =
        widget.entry.fieldType == CustomFieldType.phone &&
        (oldWidget.entry.id != widget.entry.id ||
            oldWidget.entry.fieldType != widget.entry.fieldType);
    if (shouldResyncPhoneMetadata) {
      _syncPhoneNumberState(widget.entry.value);
    }
  }

  @override
  void dispose() {
    _phoneFocusNode
      ..removeListener(_handlePhoneFocusChange)
      ..dispose();
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConcealed = widget.entry.fieldType == CustomFieldType.concealed;
    final isDateField = widget.entry.fieldType == CustomFieldType.date;
    final isPhoneField = widget.entry.fieldType == CustomFieldType.phone;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            // Строка: тип + кнопка удаления
            Row(
              children: [
                _TypeDropdown(
                  value: widget.entry.fieldType,
                  onChanged: (type) {
                    if (type != null) {
                      widget.onChanged(widget.entry.copyWith(fieldType: type));
                    }
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: widget.onRemove,
                  tooltip: 'Удалить поле',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Поле: метка
            TextField(
              controller: _labelCtrl,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Название поля',
                hintText: 'например: Серийный номер',
                isDense: true,
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.entry.copyWith(label: v)),
            ),
            const SizedBox(height: 8),
            // Поле: значение
            isPhoneField
                ? _buildPhoneValueField(context)
                : TextField(
                    controller: _valueCtrl,
                    obscureText: isConcealed && widget.entry.isObscured,
                    readOnly: isDateField,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Значение',
                      isDense: true,
                      suffixIcon: isConcealed
                          ? IconButton(
                              icon: Icon(
                                widget.entry.isObscured
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 18,
                              ),
                              onPressed: () => widget.onChanged(
                                widget.entry.copyWith(
                                  isObscured: !widget.entry.isObscured,
                                ),
                              ),
                            )
                          : isDateField
                          ? IconButton(
                              icon: const Icon(LucideIcons.calendar, size: 18),
                              tooltip: 'Выбрать дату и время',
                              onPressed: _pickDateTime,
                            )
                          : null,
                    ),
                    keyboardType: _keyboardTypeFor(widget.entry.fieldType),
                    onChanged: (v) => widget.onChanged(
                      widget.entry.copyWith(value: v.isEmpty ? null : v),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  TextInputType _keyboardTypeFor(CustomFieldType type) => switch (type) {
    CustomFieldType.email => TextInputType.emailAddress,
    CustomFieldType.url => TextInputType.url,
    CustomFieldType.phone => TextInputType.phone,
    CustomFieldType.number => TextInputType.number,
    CustomFieldType.date => TextInputType.datetime,
    _ => TextInputType.text,
  };

  Future<void> _pickDateTime() async {
    final initial = _parseDateTime(_valueCtrl.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 150),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;

    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final formatted = _dateTimeFormat.format(result);
    _valueCtrl.text = formatted;
    widget.onChanged(widget.entry.copyWith(value: formatted));
  }

  Widget _buildPhoneValueField(BuildContext context) {
    return InternationalPhoneNumberInput(
      key: ValueKey('phone_${widget.entry.id}_${widget.entry.fieldType.name}'),
      textFieldController: _valueCtrl,
      initialValue: _phoneNumber,
      focusNode: _phoneFocusNode,
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        setSelectorButtonAsPrefixIcon: true,
        useBottomSheetSafeArea: true,
        leadingPadding: 12,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),

      formatInput: true,
      autoValidateMode: AutovalidateMode.disabled,
      ignoreBlank: true,
      locale: Localizations.localeOf(context).languageCode,
      searchBoxDecoration: primaryInputDecoration(
        context,
        labelText: 'Выберите страну',
        isDense: true,
      ),

      inputDecoration: primaryInputDecoration(
        context,
        labelText: 'Значение',
        hintText: '+7 999 123-45-67',
        isDense: true,
      ).copyWith(counterText: ''),
      onInputChanged: (number) {
        final normalized = number.phoneNumber?.trim() ?? _valueCtrl.text.trim();
        _phoneNumber = number;
        _pendingPhoneValue = normalized.isEmpty ? null : normalized;
      },
      onFieldSubmitted: (_) => _commitPhoneValue(),
    );
  }

  Future<void> _syncPhoneNumberState(String? rawValue) async {
    final phoneText = rawValue?.trim();
    if (phoneText == null || phoneText.isEmpty) {
      _setPhoneNumber(PhoneNumber(isoCode: 'US'));
      return;
    }

    try {
      final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(phoneText);
      _setPhoneNumber(parsed);
    } catch (_) {
      _setPhoneNumber(
        PhoneNumber(phoneNumber: phoneText, isoCode: _phoneNumber.isoCode),
      );
    }
  }

  void _setPhoneNumber(PhoneNumber phoneNumber) {
    if (!mounted) return;
    if (_phoneNumber == phoneNumber) {
      return;
    }
    setState(() {
      _phoneNumber = phoneNumber;
    });
  }

  void _handlePhoneFocusChange() {
    if (!_phoneFocusNode.hasFocus) {
      _commitPhoneValue();
    }
  }

  void _commitPhoneValue() {
    final normalized = (_pendingPhoneValue ?? _valueCtrl.text).trim();
    final nextValue = normalized.isEmpty ? null : normalized;
    if (nextValue == widget.entry.value) {
      return;
    }
    widget.onChanged(widget.entry.copyWith(value: nextValue));
  }

  DateTime? _parseDateTime(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    try {
      return _dateTimeFormat.parseStrict(text);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Дропдаун выбора типа поля
// ─────────────────────────────────────────────────────────────────────────────

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final CustomFieldType value;
  final ValueChanged<CustomFieldType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = AppColors.getInputFieldBackgroundColor(context);

    return DropdownButton<CustomFieldType>(
      value: value,
      isDense: true,
      underline: const SizedBox.shrink(),
      dropdownColor: fillColor,
      borderRadius: BorderRadius.circular(12),

      items: CustomFieldType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(type), size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(_labelFor(type), style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static IconData _iconFor(CustomFieldType type) => switch (type) {
    CustomFieldType.text => LucideIcons.textCursor,
    CustomFieldType.concealed => LucideIcons.lock,
    CustomFieldType.url => LucideIcons.globe,
    CustomFieldType.email => LucideIcons.mail,
    CustomFieldType.phone => LucideIcons.phone,
    CustomFieldType.date => LucideIcons.calendar,
    CustomFieldType.number => LucideIcons.hash,
  };

  static String _labelFor(CustomFieldType type) => switch (type) {
    CustomFieldType.text => 'Текст',
    CustomFieldType.concealed => 'Секрет',
    CustomFieldType.url => 'URL',
    CustomFieldType.email => 'Email',
    CustomFieldType.phone => 'Телефон',
    CustomFieldType.date => 'Дата',
    CustomFieldType.number => 'Число',
  };
}
