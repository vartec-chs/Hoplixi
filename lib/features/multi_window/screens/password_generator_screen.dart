import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/password_generator_widget.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/multi_window/window_channel_service.dart';

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
  String _currentPassword = '';
  bool _channelRegistered = false;
  bool _resultSubmitted = false;

  @override
  void initState() {
    super.initState();
    _registerChannel();
  }

  /// Регистрируем канал для общения с главным окном.
  Future<void> _registerChannel() async {
    await WindowChannelService.instance.registerSubWindowHandler(
      channel: WindowChannels.passwordGenerator,
      handler: (method, args) async {
        // Главное окно может запросить текущий пароль
        if (method == 'get_current') {
          return _currentPassword;
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
    _notifyCancelIfNeeded();
    super.dispose();
  }

  Future<void> _notifyCancelIfNeeded() async {
    if (_resultSubmitted) {
      return;
    }

    try {
      await WindowChannelService.instance.cancelFromSubWindow(
        channel: WindowChannels.passwordGenerator,
      );
    } catch (_) {
      // Игнорируем — окно может быть уже закрыто
    }
  }

  /// Отправляет пароль в главное окно и закрывает
  /// это суб-окно.
  Future<void> _submitAndClose(String password) async {
    if (password.isEmpty) return;

    _resultSubmitted = true;

    await WindowChannelService.instance.submitResult(
      channel: WindowChannels.passwordGenerator,
      result: password,
    );

    // Закрываем суб-окно после отправки
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth >= 1200
                      ? 980
                      : constraints.maxWidth >= 900
                      ? 860
                      : constraints.maxWidth,
                ),
                child: PasswordGeneratorWidget(
                  padding: EdgeInsets.zero,
                  showRefreshButton: true,
                  showSubmitButton: true,
                  canSubmit: _channelRegistered,
                  submitLabel: 'Использовать',
                  onPasswordChanged: (password) {
                    _currentPassword = password;
                  },
                  onPasswordSubmitted: _channelRegistered
                      ? _submitAndClose
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
