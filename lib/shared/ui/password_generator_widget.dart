import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/password_strength_indicator.dart';

/// Кастомизируемый генератор паролей.
///
/// Может использоваться как внутри экранов,
/// так и в модальных окнах (например, WoltModalSheet).
class PasswordGeneratorWidget extends StatefulWidget {
  const PasswordGeneratorWidget({
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.initialLength = 16,
    this.minLength = 4,
    this.maxLength = 128,
    this.initialUseLowercase = true,
    this.initialUseUppercase = true,
    this.initialUseDigits = true,
    this.initialUseSpecial = true,
    this.emptyPlaceholder = 'Выберите параметры...',
    this.refreshLabel = 'Обновить',
    this.submitLabel = 'Использовать',
    this.showRefreshButton = true,
    this.showSubmitButton = true,
    this.canSubmit = true,
    this.onPasswordChanged,
    this.onPasswordSubmitted,
  });

  final EdgeInsetsGeometry padding;
  final double initialLength;
  final int minLength;
  final int maxLength;
  final bool initialUseLowercase;
  final bool initialUseUppercase;
  final bool initialUseDigits;
  final bool initialUseSpecial;
  final String emptyPlaceholder;
  final String refreshLabel;
  final String submitLabel;
  final bool showRefreshButton;
  final bool showSubmitButton;
  final bool canSubmit;
  final ValueChanged<String>? onPasswordChanged;
  final ValueChanged<String>? onPasswordSubmitted;

  @override
  State<PasswordGeneratorWidget> createState() =>
      _PasswordGeneratorWidgetState();
}

class _PasswordGeneratorWidgetState extends State<PasswordGeneratorWidget> {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  late double _length;
  late bool _useLowercase;
  late bool _useUppercase;
  late bool _useDigits;
  late bool _useSpecial;

  String _generatedPassword = '';
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _length = widget.initialLength.clamp(
      widget.minLength.toDouble(),
      widget.maxLength.toDouble(),
    );
    _useLowercase = widget.initialUseLowercase;
    _useUppercase = widget.initialUseUppercase;
    _useDigits = widget.initialUseDigits;
    _useSpecial = widget.initialUseSpecial;
    _generate();
  }

  void _generate() {
    final buffer = StringBuffer();
    if (_useLowercase) buffer.write(_lowercase);
    if (_useUppercase) buffer.write(_uppercase);
    if (_useDigits) buffer.write(_digits);
    if (_useSpecial) buffer.write(_special);

    final chars = buffer.toString();
    if (chars.isEmpty) {
      setState(() {
        _generatedPassword = '';
        _copied = false;
      });
      widget.onPasswordChanged?.call('');
      return;
    }

    final random = Random.secure();
    final password = List.generate(
      _length.round(),
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    setState(() {
      _generatedPassword = password;
      _copied = false;
    });
    widget.onPasswordChanged?.call(password);
  }

  Future<void> _copyToClipboard() async {
    if (_generatedPassword.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _generatedPassword));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(
            password: _generatedPassword,
            copied: _copied,
            placeholder: widget.emptyPlaceholder,
            onCopy: _copyToClipboard,
          ),

          const SizedBox(height: 16),

          PasswordStrengthIndicator(
            password: _generatedPassword,
            showNumericScore: true,
          ),

          const SizedBox(height: 24),

          _LengthSlider(
            length: _length,
            minLength: widget.minLength,
            maxLength: widget.maxLength,
            onChanged: (value) {
              setState(() => _length = value);
              _generate();
            },
          ),

          const SizedBox(height: 8),

          _OptionTile(
            label: 'Строчные (a-z)',
            value: _useLowercase,
            onChanged: (value) {
              setState(() => _useLowercase = value);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Прописные (A-Z)',
            value: _useUppercase,
            onChanged: (value) {
              setState(() => _useUppercase = value);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Цифры (0-9)',
            value: _useDigits,
            onChanged: (value) {
              setState(() => _useDigits = value);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Спецсимволы (!@#\$...)',
            value: _useSpecial,
            onChanged: (value) {
              setState(() => _useSpecial = value);
              _generate();
            },
          ),

          if (widget.showRefreshButton || widget.showSubmitButton) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.showRefreshButton)
                  Expanded(
                    child: SmoothButton(
                      onPressed: _generate,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: widget.refreshLabel,
                      type: .text,
                    ),
                  ),
                if (widget.showRefreshButton && widget.showSubmitButton)
                  const SizedBox(width: 12),
                if (widget.showSubmitButton)
                  Expanded(
                    child: SmoothButton(
                      onPressed:
                          widget.canSubmit &&
                              _generatedPassword.isNotEmpty &&
                              widget.onPasswordSubmitted != null
                          ? () => widget.onPasswordSubmitted!.call(
                              _generatedPassword,
                            )
                          : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: widget.submitLabel,
                      type: .filled,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.password,
    required this.copied,
    required this.placeholder,
    required this.onCopy,
  });

  final String password;
  final bool copied;
  final String placeholder;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                password.isEmpty ? placeholder : password,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onCopy,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                copied ? Icons.check : Icons.copy,
                key: ValueKey(copied),
                size: 18,
              ),
            ),
            tooltip: copied ? 'Скопировано!' : 'Копировать',
          ),
        ],
      ),
    );
  }
}

class _LengthSlider extends StatelessWidget {
  const _LengthSlider({
    required this.length,
    required this.minLength,
    required this.maxLength,
    required this.onChanged,
  });

  final double length;
  final int minLength;
  final int maxLength;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDivisions = maxLength - minLength;

    return Row(
      children: [
        Text('Длина: ${length.round()}', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Slider(
            value: length,
            min: minLength.toDouble(),
            max: maxLength.toDouble(),
            divisions: totalDivisions > 0 ? totalDivisions : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
