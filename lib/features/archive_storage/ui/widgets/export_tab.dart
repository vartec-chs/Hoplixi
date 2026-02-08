import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/archive_storage/provider/archive_notifier.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

/// Вкладка экспорта хранилища
class ExportTab extends ConsumerStatefulWidget {
  const ExportTab({super.key});

  @override
  ConsumerState<ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends ConsumerState<ExportTab> {
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
        Toaster.error(
          title: 'Ошибка экспорта',
          description: next.error!.message,
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Выбор хранилища
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выберите хранилище',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoadingStores)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.availableStores.isEmpty)
                    const NotificationCard(
                      type: NotificationType.info,
                      text: 'Нет доступных хранилищ для экспорта',
                    )
                  else
                    DropdownButtonFormField(
                      initialValue: state.selectedStore,
                      decoration: primaryInputDecoration(
                        context,
                        labelText: 'Хранилище',
                        hintText: 'Выберите хранилище',
                      ),
                      items: state.availableStores.map((store) {
                        return DropdownMenuItem(
                          value: store,
                          child: Text(store.storeName),
                        );
                      }).toList(),
                      onChanged: state.isArchiving
                          ? null
                          : notifier.selectStore,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Путь для сохранения
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Путь для сохранения',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: state.exportPath ?? '',
                          ),
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Путь',
                            hintText: 'Выберите путь для сохранения',
                          ),
                          readOnly: true,
                          enabled: !state.isArchiving,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SmoothButton(
                        label: 'Обзор...',
                        onPressed:
                            state.isArchiving || state.selectedStore == null
                            ? null
                            : notifier.pickExportPath,
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
                    'Пароль (опционально)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Пароль',
                      hintText: 'Оставьте пустым для архива без пароля',
                    ),
                    obscureText: true,
                    enabled: !state.isArchiving,
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
          if (state.isArchiving) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Архивация...',
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

          // Кнопка экспорта или начать заново
          if (state.isSuccess)
            SmoothButton(
              label: 'Начать заново',
              onPressed: notifier.clearResults,
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            )
          else
            SmoothButton(
              label: 'Экспортировать',
              onPressed:
                  state.isArchiving ||
                      state.selectedStore == null ||
                      state.exportPath == null
                  ? null
                  : notifier.exportStore,
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            ),
        ],
      ),
    );
  }
}
