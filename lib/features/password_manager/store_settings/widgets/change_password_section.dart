import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/password_generator_widget.dart';
import 'package:hoplixi/shared/ui/password_strength_indicator.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Виджет для смены пароля хранилища
class ChangePasswordSection extends ConsumerStatefulWidget {
  const ChangePasswordSection({super.key});

  @override
  ConsumerState<ChangePasswordSection> createState() =>
      _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends ConsumerState<ChangePasswordSection> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _openPasswordGeneratorModal() async {
    final generatedPassword = await WoltModalSheet.show<String>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: true,
          isTopBarLayerAlwaysVisible: true,
          topBarTitle: Text(
            'Генератор пароля',
            style: Theme.of(
              modalContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          leadingNavBarWidget: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Закрыть',
              onPressed: () => Navigator.of(modalContext).pop(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PasswordGeneratorWidget(
              showRefreshButton: true,
              showSubmitButton: true,
              submitLabel: 'Использовать пароль',
              onPasswordSubmitted: (password) {
                Navigator.of(modalContext).pop(password);
              },
            ),
          ),
        ),
      ],
    );

    if (!mounted || generatedPassword == null || generatedPassword.isEmpty) {
      return;
    }

    final notifier = ref.read(storeSettingsProvider.notifier);
    _newPasswordController.text = generatedPassword;
    _confirmPasswordController.text = generatedPassword;
    notifier.updateNewPassword(generatedPassword);
    notifier.updateNewPasswordConfirmation(generatedPassword);
  }

  @override
  void dispose() {
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
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    ref.read(storeSettingsProvider.notifier).resetPasswordFields();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

        if (state.newPassword.isNotEmpty) ...[
          const SizedBox(height: 8),
          PasswordStrengthIndicator(password: state.newPassword),
        ],

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

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: SmoothButton(
            onPressed: state.isChangingPassword
                ? null
                : _openPasswordGeneratorModal,
            icon: const Icon(Icons.password, size: 18),
            label: 'Сгенерировать пароль',
            type: SmoothButtonType.text,
            size: SmoothButtonSize.small,
          ),
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
