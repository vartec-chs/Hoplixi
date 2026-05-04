import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class KeyFileSecuritySection extends ConsumerStatefulWidget {
  const KeyFileSecuritySection({super.key});

  @override
  ConsumerState<KeyFileSecuritySection> createState() =>
      _KeyFileSecuritySectionState();
}

class _KeyFileSecuritySectionState
    extends ConsumerState<KeyFileSecuritySection> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    final result = await ref
        .read(storeSettingsProvider.notifier)
        .enableKeyFile(_passwordController.text);
    if (!mounted) return;
    result.fold((_) => _passwordController.clear(), (_) {});
  }

  Future<void> _disable() async {
    final result = await ref
        .read(storeSettingsProvider.notifier)
        .disableKeyFile(_passwordController.text);
    if (!mounted) return;
    result.fold((_) => _passwordController.clear(), (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);
    final notifier = ref.read(storeSettingsProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.keyFileSettingsError != null) ...[
            NotificationCard(
              type: NotificationType.error,
              text: state.keyFileSettingsError!,
              onDismiss: notifier.clearMessages,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            state.useKeyFile
                ? 'JSON key file включён'
                : 'JSON key file отключён',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.keyFileHint != null || state.keyFileId != null) ...[
            const SizedBox(height: 8),
            Text(
              state.keyFileHint ?? state.keyFileId!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Текущий мастер пароль',
              prefixIcon: const Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmoothButton(
                label: 'Выбрать JSON key file',
                icon: const Icon(Icons.upload_file),
                type: SmoothButtonType.outlined,
                onPressed: state.isUpdatingKeyFile
                    ? null
                    : notifier.selectKeyFileForSettings,
              ),
              if (!state.useKeyFile)
                SmoothButton(
                  label: 'Сгенерировать',
                  icon: const Icon(Icons.add),
                  type: SmoothButtonType.outlined,
                  onPressed: state.isUpdatingKeyFile
                      ? null
                      : notifier.generateKeyFileForSettings,
                ),
            ],
          ),
          if (state.selectedKeyFileId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Выбран key file: ${state.selectedKeyFileHint ?? state.selectedKeyFileId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SmoothButton(
            label: state.useKeyFile
                ? 'Отключить key file'
                : 'Включить key file',
            icon: Icon(state.useKeyFile ? Icons.key_off : Icons.key),
            loading: state.isUpdatingKeyFile,
            onPressed: state.isUpdatingKeyFile
                ? null
                : state.useKeyFile
                ? _disable
                : _enable,
          ),
        ],
      ),
    );
  }
}
