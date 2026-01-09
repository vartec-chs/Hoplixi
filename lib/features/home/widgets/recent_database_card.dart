import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/main_store/models/db_history_model.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/provider/db_history_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class RecentDatabaseCard extends ConsumerWidget {
  const RecentDatabaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentDbAsync = ref.watch(recentDatabaseProvider);

    return recentDbAsync.when(
      data: (entry) {
        if (entry == null) return const SizedBox.shrink();
        return Column(
          spacing: 4,
          children: [_buildCard(context, ref, entry), const Divider()],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, DatabaseEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Недавняя база данных',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  tooltip: 'Удалить из истории',
                  onPressed: () => _deleteFromHistory(context, ref, entry),
                  color: colorScheme.error,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (entry.description != null && entry.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              entry.path,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SmoothButton(
                label: 'Открыть',
                type: SmoothButtonType.outlined,
                icon: const Icon(CupertinoIcons.arrow_right_circle),
                onPressed: () => _openDatabase(context, ref, entry),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDatabase(
    BuildContext context,
    WidgetRef ref,
    DatabaseEntry entry,
  ) async {
    final notifier = ref.read(mainStoreProvider.notifier);
    String? password = entry.password;
    bool shouldSavePassword = false;

    if (!entry.savePassword || password == null) {
      final result = await showDialog<(String, bool)>(
        context: context,
        builder: (context) => _PasswordDialog(dbName: entry.name),
      );

      if (result == null) return; // User cancelled
      password = result.$1;
      shouldSavePassword = result.$2;
    }

    final success = await notifier.openStore(
      OpenStoreDto(path: entry.path, password: password),
    );

    if (success) {
      Toaster.success(title: 'Успех', description: 'База данных открыта');

      if (shouldSavePassword) {
        final historyService = await ref.read(dbHistoryProvider.future);
        final freshEntry = await historyService.getByPath(entry.path);
        if (freshEntry != null) {
          final updatedEntry = freshEntry.copyWith(
            password: password,
            savePassword: true,
          );
          await historyService.update(updatedEntry);
          ref.invalidate(recentDatabaseProvider);
        }
      }
    } else {
      final state = ref.read(mainStoreProvider);
      final errorMessage =
          state.value?.error?.message ?? 'Не удалось открыть базу данных';
      Toaster.error(title: 'Ошибка', description: errorMessage);
    }
  }

  Future<void> _deleteFromHistory(
    BuildContext context,
    WidgetRef ref,
    DatabaseEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из истории'),
        content: Text(
          'Удалить "${entry.name}" из истории?\n\nФайлы базы данных на диске останутся без изменений.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final historyService = await ref.read(dbHistoryProvider.future);
      await historyService.deleteByPath(entry.path);
      ref.invalidate(recentDatabaseProvider);

      if (context.mounted) {
        Toaster.success(
          title: 'Успех',
          description: 'База данных удалена из истории',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка',
          description: 'Не удалось удалить из истории: $e',
        );
      }
    }
  }
}

class _PasswordDialog extends StatefulWidget {
  final String dbName;

  const _PasswordDialog({required this.dbName});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;
  bool _savePassword = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Введите пароль для "${widget.dbName}"'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Пароль',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              onSubmitted: (value) =>
                  Navigator.of(context).pop((value, _savePassword)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Сохранить пароль'),
              value: _savePassword,
              onChanged: (value) {
                setState(() {
                  _savePassword = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        SmoothButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Отмена',

          variant: SmoothButtonVariant.error,
          type: SmoothButtonType.text,
        ),
        SmoothButton(
          label: 'Открыть',

          onPressed: () =>
              Navigator.of(context).pop((_controller.text, _savePassword)),
        ),
      ],
    );
  }
}
