import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Форма настроек хранилища
class StoreSettingsForm extends ConsumerStatefulWidget {
  const StoreSettingsForm({super.key});

  @override
  ConsumerState<StoreSettingsForm> createState() => _StoreSettingsFormState();
}

class _StoreSettingsFormState extends ConsumerState<StoreSettingsForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры текущими значениями
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(storeSettingsProvider);
      _nameController.text = state.newName;
      _descriptionController.text = state.newDescription ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(storeSettingsProvider.notifier);
    final result = await notifier.save();

    if (!mounted) return;

    result.fold(
      (success) {
        Toaster.success(
          title: 'Успешно',
          description: 'Настройки хранилища сохранены',
        );
        Navigator.of(context).pop(true);
      },
      (error) {
        Toaster.error(title: 'Ошибка', description: error);
      },
    );
  }

  void _handleReset() {
    final notifier = ref.read(storeSettingsProvider.notifier);
    notifier.reset();

    final state = ref.read(storeSettingsProvider);
    _nameController.text = state.newName;
    _descriptionController.text = state.newDescription ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ошибка
          if (state.saveError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: NotificationCard(
                type: NotificationType.error,
                text: state.saveError!,
                onDismiss: () {
                  ref.read(storeSettingsProvider.notifier).clearMessages();
                },
              ),
            ),

          // Поле имени
          TextField(
            controller: _nameController,
            enabled: !state.isSaving,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Имя хранилища',
              hintText: 'Введите имя хранилища',
              errorText: state.nameError,
            ),
            onChanged: (value) {
              ref.read(storeSettingsProvider.notifier).updateName(value);
            },
          ),

          const SizedBox(height: 16),

          // Поле описания
          TextField(
            controller: _descriptionController,
            enabled: !state.isSaving,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Описание',
              hintText: 'Введите описание хранилища (необязательно)',
            ),
            maxLines: 3,
            onChanged: (value) {
              ref.read(storeSettingsProvider.notifier).updateDescription(value);
            },
          ),

          const SizedBox(height: 24),

          // Кнопки действий
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Кнопка сброса
              SmoothButton(
                label: 'Сбросить',
                onPressed: state.canSave && !state.isSaving
                    ? _handleReset
                    : null,
                type: SmoothButtonType.text,
                variant: SmoothButtonVariant.normal,
              ),

              const SizedBox(width: 8),

              // Кнопка отмены
              SmoothButton(
                label: 'Отменить',
                onPressed: state.isSaving
                    ? null
                    : () => Navigator.of(context).pop(false),
                type: SmoothButtonType.outlined,
                variant: SmoothButtonVariant.normal,
              ),

              const SizedBox(width: 8),

              // Кнопка сохранения
              SmoothButton(
                label: state.isSaving ? 'Сохранение...' : 'Сохранить',
                onPressed: state.canSave && !state.isSaving
                    ? _handleSave
                    : null,
                type: SmoothButtonType.filled,
                variant: SmoothButtonVariant.normal,
                loading: state.isSaving,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
