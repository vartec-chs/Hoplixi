import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Виджет для смены пароля хранилища
class ChangePasswordSection extends ConsumerStatefulWidget {
  const ChangePasswordSection({super.key});

  @override
  ConsumerState<ChangePasswordSection> createState() =>
      _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends ConsumerState<ChangePasswordSection> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final notifier = ref.read(storeSettingsProvider.notifier);
    final result = await notifier.changePassword();

    if (!mounted) return;

    result.fold(
      (success) {
        Toaster.success(
          title: 'Успешно',
          description: 'Пароль успешно изменен',
        );
        _clearFields();
      },
      (error) {
        Toaster.error(title: 'Ошибка', description: error);
      },
    );
  }

  void _clearFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    ref.read(storeSettingsProvider.notifier).resetPasswordFields();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),

        // Заголовок секции
        Text(
          'Смена пароля',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        // Текущий пароль
        TextField(
          controller: _currentPasswordController,
          enabled: !state.isChangingPassword,
          obscureText: _obscureCurrentPassword,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Текущий пароль',
            hintText: 'Введите текущий пароль',
            errorText: state.currentPasswordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrentPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
          ),
          onChanged: (value) {
            ref
                .read(storeSettingsProvider.notifier)
                .updateCurrentPassword(value);
          },
        ),

        const SizedBox(height: 16),

        // Новый пароль
        TextField(
          controller: _newPasswordController,
          enabled: !state.isChangingPassword,
          obscureText: _obscureNewPassword,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Новый пароль',
            hintText: 'Введите новый пароль',
            errorText: state.newPasswordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
          ),
          onChanged: (value) {
            ref.read(storeSettingsProvider.notifier).updateNewPassword(value);
          },
        ),

        const SizedBox(height: 16),

        // Подтверждение нового пароля
        TextField(
          controller: _confirmPasswordController,
          enabled: !state.isChangingPassword,
          obscureText: _obscureConfirmPassword,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Подтвердите новый пароль',
            hintText: 'Введите новый пароль еще раз',
            errorText: state.newPasswordConfirmationError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          onChanged: (value) {
            ref
                .read(storeSettingsProvider.notifier)
                .updateNewPasswordConfirmation(value);
          },
        ),

        const SizedBox(height: 24),

        // Кнопки
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SmoothButton(
              label: 'Очистить',
              onPressed: state.isChangingPassword ? null : _clearFields,
              type: SmoothButtonType.text,
              variant: SmoothButtonVariant.normal,
            ),
            const SizedBox(width: 8),
            SmoothButton(
              label: state.isChangingPassword
                  ? 'Изменение...'
                  : 'Изменить пароль',
              onPressed: state.canChangePassword && !state.isChangingPassword
                  ? _handleChangePassword
                  : null,
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
              loading: state.isChangingPassword,
            ),
          ],
        ),
      ],
    );
  }
}
