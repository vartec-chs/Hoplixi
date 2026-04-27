import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/new/ui/store_open_migration_dialog.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_form_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Форма для ввода пароля при открытии хранилища
class PasswordForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const PasswordForm({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  ConsumerState<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends ConsumerState<PasswordForm> {
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _passwordController.addListener(_onPasswordChanged);
    _passwordFocusNode = FocusNode();
    // Автофокус на поле пароля
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.requestFocus();
    });
  }

  void _onPasswordChanged() {
    final notifier = ref.read(openStoreFormProvider.notifier);
    notifier.updatePassword(_passwordController.text);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(openStoreFormProvider.notifier);
    final success = await notifier.openStorage();

    if (success && mounted) {
      widget.onSuccess();
      return;
    }

    if (!mounted) {
      return;
    }

    final state = ref.read(openStoreFormProvider).value;
    final storage = state?.selectedStorage;
    if (storage == null) {
      return;
    }

    await promptStoreMigrationAndOpen(
      context: context,
      ref: ref,
      dto: OpenStoreDto(path: storage.path, password: _passwordController.text),
      onOpened: () async {
        widget.onSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final asyncState = ref.watch(openStoreFormProvider);
    final state = asyncState.value;

    if (state == null || state.selectedStorage == null) {
      return const SizedBox.shrink();
    }

    final storage = state.selectedStorage!;
    final isOpening = state.isOpening;
    final passwordError = state.passwordError;
    final password = state.password;

    return Focus(
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          if (!isOpening && password.isNotEmpty) {
            _handleSubmit();
            return KeyEventResult.handled;
          }
        } else if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
          if (!isOpening) {
            widget.onCancel();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(
                    Icons.lock_outlined,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Открытие хранилища',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          storage.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Информация о хранилище
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Последнее изменение: ${storage.formattedModifiedDate}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Размер: ${storage.formattedSize}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Поле ввода пароля
              PasswordField(
                label: 'Пароль',
                controller: _passwordController,
                autofocus: true,
              ),
              if (passwordError != null) ...[
                const SizedBox(height: 8),
                Text(
                  passwordError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SmoothButton(
                    label: 'Отмена',
                    type: SmoothButtonType.text,
                    onPressed: isOpening ? null : widget.onCancel,
                  ),
                  const SizedBox(width: 12),
                  SmoothButton(
                    label: 'Открыть',
                    type: SmoothButtonType.filled,
                    loading: isOpening,
                    onPressed: isOpening || password.isEmpty
                        ? null
                        : _handleSubmit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
