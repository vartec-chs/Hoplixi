import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';

final recentDatabaseHistoryControllerProvider =
    Provider<RecentDatabaseHistoryController>((ref) {
      return RecentDatabaseHistoryController(ref);
    });

class RecentDatabaseHistoryController {
  const RecentDatabaseHistoryController(this.ref);

  final Ref ref;

  Future<void> deleteFromHistory(
    BuildContext context,
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
