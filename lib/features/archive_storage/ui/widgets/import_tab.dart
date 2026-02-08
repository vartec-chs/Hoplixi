import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/archive_storage/provider/archive_notifier.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Вкладка импорта хранилища
class ImportTab extends ConsumerStatefulWidget {
  const ImportTab({super.key});

  @override
  ConsumerState<ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<ImportTab> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(archiveNotifierProvider);
    final notifier = ref.read(archiveNotifierProvider.notifier);

    ref.listen(archiveNotifierProvider, (prev, next) {
      // Показываем успех только если состояние изменилось с false на true
      if (next.isSuccess &&
          next.successMessage != null &&
          (prev == null || !prev.isSuccess)) {
        Toaster.success(title: 'Успех', description: next.successMessage!);
      }
      // Показываем ошибку только если она новая
      if (next.error != null && (prev == null || prev.error != next.error)) {
        // Специальное сообщение для ошибки неверного пароля
        final isPasswordError = next.error is ArchiveInvalidPasswordError;
        Toaster.error(
          title: isPasswordError ? 'Неверный пароль' : 'Ошибка импорта',
          description: isPasswordError
              ? 'Проверьте пароль и попробуйте снова'
              : next.error!.message,
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Выбор файла архива
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выберите архив',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: state.importPath ?? '',
                          ),
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Файл архива',
                            hintText: 'Выберите файл .zip',
                          ),
                          readOnly: true,
                          enabled: !state.isUnarchiving,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SmoothButton(
                        label: 'Обзор...',
                        onPressed: state.isUnarchiving
                            ? null
                            : notifier.pickImportFile,
                        type: SmoothButtonType.outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Пароль (опционально)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пароль (если требуется)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Пароль',
                      hintText: 'Оставьте пустым если архив без пароля',
                    ),
                    obscureText: true,
                    enabled: !state.isUnarchiving,
                    onChanged: (value) {
                      notifier.setPassword(value.isEmpty ? null : value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Прогресс
          if (state.isUnarchiving) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Разархивация...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: state.progress),
                    const SizedBox(height: 8),
                    Text(
                      '${(state.progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (state.currentFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Текущий файл: ${state.currentFile}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Информация
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Хранилище будет импортировано в папку storages с автоматически сгенерированным именем',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Кнопка импорта или начать заново
          if (state.isSuccess)
            SmoothButton(
              label: 'Начать заново',
              onPressed: notifier.clearResults,
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            )
          else
            SmoothButton(
              label: 'Импортировать',
              onPressed: state.isUnarchiving || state.importPath == null
                  ? null
                  : notifier.importStore,
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            ),
        ],
      ),
    );
  }
}
