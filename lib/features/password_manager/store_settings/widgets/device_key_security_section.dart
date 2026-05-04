import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class DeviceKeySecuritySection extends ConsumerStatefulWidget {
  const DeviceKeySecuritySection({super.key});

  @override
  ConsumerState<DeviceKeySecuritySection> createState() =>
      _DeviceKeySecuritySectionState();
}

class _DeviceKeySecuritySectionState
    extends ConsumerState<DeviceKeySecuritySection> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    final result = await ref
        .read(storeSettingsProvider.notifier)
        .enableDeviceKey(_passwordController.text);
    if (!mounted) return;
    result.fold((_) => _passwordController.clear(), (_) {});
  }

  Future<void> _disable() async {
    final result = await ref
        .read(storeSettingsProvider.notifier)
        .disableDeviceKey(_passwordController.text);
    if (!mounted) return;
    result.fold((_) => _passwordController.clear(), (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);
    final notifier = ref.read(storeSettingsProvider.notifier);
    final theme = Theme.of(context);

    if (_passwordController.text != state.deviceKeyPassword) {
      _passwordController.text = state.deviceKeyPassword;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.deviceKeySettingsError != null) ...[
            NotificationCard(
              type: NotificationType.error,
              text: state.deviceKeySettingsError!,
              onDismiss: notifier.clearMessages,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            state.useDeviceKey
                ? 'Ключ устройства включён'
                : 'Ключ устройства отключён',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Переключение требует текущий мастер пароль. Если у хранилища также включён JSON key file, сначала выберите текущий key file на соседней странице.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (state.keyFileHint != null || state.keyFileId != null) ...[
            const SizedBox(height: 8),
            Text(
              state.keyFileHint ?? state.keyFileId!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            enabled: !state.isUpdatingDeviceKey,
            obscureText: true,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Текущий мастер пароль',
              prefixIcon: const Icon(Icons.lock),
            ),
            onChanged: (value) {
              ref
                  .read(storeSettingsProvider.notifier)
                  .updateDeviceKeyPassword(value);
            },
          ),
          const SizedBox(height: 24),
          if (state.useDeviceKey)
            Row(
              children: [
                Icon(Icons.phonelink_lock, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ключ устройства активен и подмешивается к ключу хранилища.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.phonelink, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'При включении ключ устройства это хранилище будет открываться только на этом устройстве.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          SmoothButton(
            label: state.useDeviceKey
                ? 'Отключить ключ устройства'
                : 'Включить ключ устройства',
            icon: Icon(
              state.useDeviceKey ? Icons.phonelink_off : Icons.phonelink_lock,
            ),
            loading: state.isUpdatingDeviceKey,
            onPressed: state.isUpdatingDeviceKey
                ? null
                : state.useDeviceKey
                ? _disable
                : _enable,
          ),
        ],
      ),
    );
  }
}
