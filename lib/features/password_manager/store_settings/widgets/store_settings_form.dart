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
  final _historyLimitController = TextEditingController();
  final _historyMaxAgeDaysController = TextEditingController();
  final _historyCleanupIntervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Контроллеры будут инициализированы в build методе
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _historyLimitController.dispose();
    _historyMaxAgeDaysController.dispose();
    _historyCleanupIntervalController.dispose();
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
    _historyLimitController.text = state.newHistoryLimit.toString();
    _historyMaxAgeDaysController.text = state.newHistoryMaxAgeDays.toString();
    _historyCleanupIntervalController.text = state.newHistoryCleanupIntervalDays
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);

    // Обновляем контроллеры при изменении состояния
    if (_nameController.text != state.newName) {
      _nameController.text = state.newName;
    }
    if (_descriptionController.text != (state.newDescription ?? '')) {
      _descriptionController.text = state.newDescription ?? '';
    }

    final limitString = state.newHistoryLimit.toString();
    final currentLimit = int.tryParse(_historyLimitController.text);
    if (currentLimit != state.newHistoryLimit) {
      _historyLimitController.text = limitString;
    }

    final ageString = state.newHistoryMaxAgeDays.toString();
    final currentAge = int.tryParse(_historyMaxAgeDaysController.text);
    if (currentAge != state.newHistoryMaxAgeDays) {
      _historyMaxAgeDaysController.text = ageString;
    }

    final intervalString = state.newHistoryCleanupIntervalDays.toString();
    final currentInterval = int.tryParse(
      _historyCleanupIntervalController.text,
    );
    if (currentInterval != state.newHistoryCleanupIntervalDays) {
      _historyCleanupIntervalController.text = intervalString;
    }

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

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'История изменений',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Сохранять историю изменений'),
            value: state.newHistoryEnabled,
            onChanged: state.isSaving
                ? null
                : (value) {
                    ref
                        .read(storeSettingsProvider.notifier)
                        .updateHistoryEnabled(value);
                  },
            contentPadding: EdgeInsets.zero,
          ),

          if (state.newHistoryEnabled) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _historyLimitController,
              enabled: !state.isSaving,
              keyboardType: TextInputType.number,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Лимит записей в истории (макс. на элемент)',
                hintText: 'Например, 100',
              ),
              onChanged: (value) {
                final limit = int.tryParse(value) ?? 100;
                ref
                    .read(storeSettingsProvider.notifier)
                    .updateHistoryLimit(limit);
              },
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _historyMaxAgeDaysController,
              enabled: !state.isSaving,
              keyboardType: TextInputType.number,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Максимальный возраст записей истории (в днях)',
                hintText: 'Например, 30',
              ),
              onChanged: (value) {
                final days = int.tryParse(value) ?? 30;
                ref
                    .read(storeSettingsProvider.notifier)
                    .updateHistoryMaxAgeDays(days);
              },
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _historyCleanupIntervalController,
              enabled: !state.isSaving,
              keyboardType: TextInputType.number,
              decoration: primaryInputDecoration(
                context,
                labelText:
                    'Периодичность очистки истории (в днях, работает фоново при входе)',
                hintText: 'Например, 7',
              ),
              onChanged: (value) {
                final interval = int.tryParse(value) ?? 7;
                ref
                    .read(storeSettingsProvider.notifier)
                    .updateHistoryCleanupIntervalDays(interval);
              },
            ),
          ],

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
