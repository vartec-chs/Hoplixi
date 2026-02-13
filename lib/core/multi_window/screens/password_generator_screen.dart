import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../window_channel_service.dart';

/// Экран генератора паролей для отдельного суб-окна.
///
/// Позволяет гибко настроить параметры генерации пароля
/// (длина, символы, цифры и т.д.) и скопировать результат
/// в буфер обмена.
///
/// При вызове через [MultiWindowService.openAndWaitResult]
/// кнопка «Использовать» отправляет сгенерированный пароль
/// обратно в главное окно через [WindowChannels.passwordGenerator].
class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  double _length = 16;
  bool _useLowercase = true;
  bool _useUppercase = true;
  bool _useDigits = true;
  bool _useSpecial = true;

  String _generatedPassword = '';
  bool _copied = false;
  bool _channelRegistered = false;

  @override
  void initState() {
    super.initState();
    _generate();
    _registerChannel();
  }

  /// Регистрируем канал для общения с главным окном.
  Future<void> _registerChannel() async {
    await WindowChannelService.instance.registerSubWindowHandler(
      channel: WindowChannels.passwordGenerator,
      handler: (method, args) async {
        // Главное окно может запросить текущий пароль
        if (method == 'get_current') {
          return _generatedPassword;
        }
        return null;
      },
    );
    if (mounted) {
      setState(() => _channelRegistered = true);
    }
  }

  @override
  void dispose() {
    // Уведомляем главное окно об отмене,
    // если пользователь закрыл окно без выбора
    _notifyCancel();
    super.dispose();
  }

  Future<void> _notifyCancel() async {
    try {
      await WindowChannelService.instance.cancelFromSubWindow(
        channel: WindowChannels.passwordGenerator,
      );
    } catch (_) {
      // Игнорируем — окно может быть уже закрыто
    }
  }

  void _generate() {
    final buffer = StringBuffer();
    if (_useLowercase) buffer.write(_lowercase);
    if (_useUppercase) buffer.write(_uppercase);
    if (_useDigits) buffer.write(_digits);
    if (_useSpecial) buffer.write(_special);

    final chars = buffer.toString();
    if (chars.isEmpty) {
      setState(() => _generatedPassword = '');
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
  }

  Future<void> _copyToClipboard() async {
    if (_generatedPassword.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _generatedPassword));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  /// Отправляет пароль в главное окно и закрывает
  /// это суб-окно.
  Future<void> _submitAndClose() async {
    if (_generatedPassword.isEmpty) return;

    await WindowChannelService.instance.submitResult(
      channel: WindowChannels.passwordGenerator,
      result: _generatedPassword,
    );

    // Закрываем суб-окно после отправки
    await windowManager.close();
  }

  /// Оценка сложности пароля (0.0 - 1.0).
  double get _strength {
    if (_generatedPassword.isEmpty) return 0;
    var score = 0.0;
    if (_useLowercase) score += 0.2;
    if (_useUppercase) score += 0.2;
    if (_useDigits) score += 0.2;
    if (_useSpecial) score += 0.2;
    if (_length >= 12) score += 0.1;
    if (_length >= 20) score += 0.1;
    return score.clamp(0.0, 1.0);
  }

  Color _strengthColor(double value) {
    if (value < 0.4) return Colors.red;
    if (value < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _strengthLabel(double value) {
    if (value < 0.4) return 'Слабый';
    if (value < 0.7) return 'Средний';
    return 'Сильный';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strength = _strength;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Поле с паролем
          _PasswordField(
            password: _generatedPassword,
            copied: _copied,
            onCopy: _copyToClipboard,
          ),

          const SizedBox(height: 16),

          // Индикатор сложности
          _StrengthIndicator(
            strength: strength,
            color: _strengthColor(strength),
            label: _strengthLabel(strength),
          ),

          const SizedBox(height: 24),

          // Слайдер длины
          _LengthSlider(
            length: _length,
            onChanged: (v) {
              setState(() => _length = v);
              _generate();
            },
          ),

          const SizedBox(height: 8),

          // Переключатели символов
          _OptionTile(
            label: 'Строчные (a-z)',
            value: _useLowercase,
            onChanged: (v) {
              setState(() => _useLowercase = v);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Прописные (A-Z)',
            value: _useUppercase,
            onChanged: (v) {
              setState(() => _useUppercase = v);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Цифры (0-9)',
            value: _useDigits,
            onChanged: (v) {
              setState(() => _useDigits = v);
              _generate();
            },
          ),
          _OptionTile(
            label: 'Спецсимволы (!@#\$...)',
            value: _useSpecial,
            onChanged: (v) {
              setState(() => _useSpecial = v);
              _generate();
            },
          ),

          const Spacer(),

          // Кнопки: генерация + использовать
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Обновить'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _channelRegistered && _generatedPassword.isNotEmpty
                      ? _submitAndClose
                      : null,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Использовать'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Поле с отображением пароля и кнопкой копирования.
class _PasswordField extends StatelessWidget {
  final String password;
  final bool copied;
  final VoidCallback onCopy;

  const _PasswordField({
    required this.password,
    required this.copied,
    required this.onCopy,
  });

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
            child: SelectableText(
              password.isEmpty ? 'Выберите параметры...' : password,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
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

/// Индикатор сложности пароля.
class _StrengthIndicator extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;

  const _StrengthIndicator({
    required this.strength,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Слайдер длины пароля.
class _LengthSlider extends StatelessWidget {
  final double length;
  final ValueChanged<double> onChanged;

  const _LengthSlider({required this.length, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text('Длина: ${length.round()}', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Slider(
            value: length,
            min: 4,
            max: 128,
            divisions: 124,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Строка-переключатель для опций генератора.
class _OptionTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

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
