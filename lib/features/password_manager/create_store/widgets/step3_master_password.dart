import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/features/password_manager/create_store/providers/create_store_form_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/password_generator_widget.dart';
import 'package:hoplixi/shared/ui/password_strength_indicator.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Шаг 3: Мастер пароль
class Step3MasterPassword extends ConsumerStatefulWidget {
  const Step3MasterPassword({super.key});

  @override
  ConsumerState<Step3MasterPassword> createState() =>
      _Step3MasterPasswordState();
}

class _Step3MasterPasswordState extends ConsumerState<Step3MasterPassword> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmationController;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmationFocusNode;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

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

    final notifier = ref.read(createStoreFormProvider.notifier);
    _passwordController.text = generatedPassword;
    _confirmationController.text = generatedPassword;
    notifier.updatePassword(generatedPassword);
    notifier.updatePasswordConfirmation(generatedPassword);
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(createStoreFormProvider);
    _passwordController = TextEditingController(text: state.password);
    _confirmationController = TextEditingController(
      text: state.passwordConfirmation,
    );
    _passwordFocusNode = FocusNode();
    _confirmationFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    _passwordFocusNode.dispose();
    _confirmationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createStoreFormProvider);
    final notifier = ref.read(createStoreFormProvider.notifier);

    return SingleChildScrollView(
      padding: screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Мастер пароль',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте надежный пароль для защиты вашего хранилища',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Поле пароля
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            autofocus: true,
            onSubmitted: (_) {
              _confirmationFocusNode.requestFocus();
            },
            decoration: primaryInputDecoration(
              context,
              labelText: 'Мастер пароль *',
              hintText: 'Минимум 4 символов',
              errorText: state.passwordError,

              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            onChanged: notifier.updatePassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),

          // Индикатор сложности пароля
          if (state.password.isNotEmpty)
            PasswordStrengthIndicator(
              password: state.password,
              minHeight: 8,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 24),

          // Поле подтверждения
          TextField(
            controller: _confirmationController,
            focusNode: _confirmationFocusNode,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Подтвердите пароль *',
              hintText: 'Введите пароль еще раз',
              errorText: state.passwordConfirmationError,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmation = !_obscureConfirmation;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmation,
            onChanged: notifier.updatePasswordConfirmation,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: SmoothButton(
              onPressed: _openPasswordGeneratorModal,
              icon: const Icon(Icons.password, size: 18),
              label: 'Сгенерировать пароль',
              type: .text,
              size: .small,
            ),
          ),
          const SizedBox(height: 24),

          // Переключатель использования ключа устройства
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phonelink_lock,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Использовать ключ устройства',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Хранилище будет защищено дополнительно с помощью ключа устройства',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: state.useDeviceKey,
                      onChanged: notifier.setUseDeviceKey,
                    ),
                  ],
                ),
                if (state.useDeviceKey) ...[
                  const SizedBox(height: 16),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ВАЖНО: ключ устройства подмешивается к ключу хранилища. Без данного устройства будет невозможно открыть это хранилище (например, если скопировать файл БД на другой ПК).',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Требования к паролю
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Требования к паролю:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RequirementItem(
                  text: 'Минимум 4 символов',
                  isMet: state.password.length >= 4,
                ),
                // _RequirementItem(
                //   text: 'Заглавные и строчные буквы',
                //   isMet:
                //       state.password.contains(RegExp(r'[A-Z]')) &&
                //       state.password.contains(RegExp(r'[a-z]')),
                // ),
                // _RequirementItem(
                //   text: 'Цифры',
                //   isMet: state.password.contains(RegExp(r'[0-9]')),
                // ),
                // _RequirementItem(
                //   text: 'Специальные символы (!@#\$%^&*)',
                //   isMet: state.password.contains(
                //     RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                //   ),
                // ),
                _RequirementItem(
                  text: 'Пароли совпадают',
                  isMet:
                      state.password.isNotEmpty &&
                      state.password == state.passwordConfirmation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Предупреждение
          const NotificationCard(
            type: .warning,
            text:
                'ВАЖНО: Запомните или надежно сохраните этот пароль. Восстановление невозможно!',
          ),
        ],
      ),
    );
  }
}

/// Элемент требования к паролю
class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _RequirementItem({required this.text, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isMet
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
