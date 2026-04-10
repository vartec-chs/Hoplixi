import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/archive_storage/provider/archive_notifier.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
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
      if (next.isSuccess &&
          next.successMessage != null &&
          (prev == null || !prev.isSuccess)) {
        Toaster.success(title: 'Успех', description: next.successMessage!);
      }

      if (next.error != null && (prev == null || prev.error != next.error)) {
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Параметры импорта',
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
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.replaceExistingIfNewer,
                    onChanged: state.isUnarchiving
                        ? null
                        : notifier.setReplaceExistingIfNewer,
                    title: const Text('Заменять существующее хранилище'),
                    subtitle: const Text(
                      'Если найдено хранилище с тем же store ID и архив новее по manifest, текущая версия будет перенесена в backups.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.replaceExistingIfNewer
                          ? 'Если архив новее локального хранилища с тем же store ID, существующая папка будет перенесена в backups, а архив займёт её место.'
                          : 'Хранилище будет импортировано в папку storages с автоматически сгенерированным именем.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
