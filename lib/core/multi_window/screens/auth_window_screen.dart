import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../window_channel_service.dart';

/// Экран авторизации, открываемый в отдельном суб-окне.
///
/// Используется для ввода учётных данных без переключения
/// контекста основного окна.
///
/// При нажатии «Войти» отправляет данные авторизации
/// обратно в главное окно через [WindowChannels.auth]
/// и закрывает суб-окно.
class AuthWindowScreen extends StatefulWidget {
  /// Дополнительные данные, переданные через payload.
  final Map<String, dynamic> payload;

  const AuthWindowScreen({super.key, this.payload = const {}});

  @override
  State<AuthWindowScreen> createState() => _AuthWindowScreenState();
}

class _AuthWindowScreenState extends State<AuthWindowScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _channelRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerChannel();
  }

  Future<void> _registerChannel() async {
    await WindowChannelService.instance.registerSubWindowHandler(
      channel: WindowChannels.auth,
      handler: (method, args) async {
        // Главное окно может запросить статус
        if (method == 'get_status') {
          return 'ready';
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
    _notifyCancel();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _notifyCancel() async {
    try {
      await WindowChannelService.instance.cancelFromSubWindow(
        channel: WindowChannels.auth,
      );
    } catch (_) {
      // Игнорируем — окно может быть уже закрыто
    }
  }

  /// Отправляет данные и закрывает суб-окно.
  Future<void> _submitAndClose() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) return;

    await WindowChannelService.instance.submitResult(
      channel: WindowChannels.auth,
      result: {'login': login, 'password': password},
    );

    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline, size: 56, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Вход в систему',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.payload['reason'] != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.payload['reason'] as String,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 32),
          TextField(
            controller: _loginController,
            decoration: InputDecoration(
              labelText: 'Логин',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitAndClose(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _channelRegistered ? _submitAndClose : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}
