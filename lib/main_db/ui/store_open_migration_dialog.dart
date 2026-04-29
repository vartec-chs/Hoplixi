import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/providers/main_store_backup_orchestrator_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/shared/ui/button.dart';

bool isStoreMigrationRequiredError(AppError? error) {
  return error?.codeString == MainDatabaseErrorCode.storeMigrationRequired.value;
}

Future<bool> promptStoreMigrationAndOpen({
  required BuildContext context,
  required WidgetRef ref,
  required OpenStoreDto dto,
  Future<void> Function()? onOpened,
}) async {
  final error = ref.read(mainStoreProvider).value?.error;
  if (!isStoreMigrationRequiredError(error)) {
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Нужна миграция хранилища'),
        content: Text(_buildMigrationDescription(error)),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: 'Отмена',
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: 'Backup и миграция',
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return true;
  }

  final success = await ref
      .read(mainStoreBackupOrchestratorProvider)
      .backupAndMigrateStore(dto);
  if (!context.mounted) {
    return true;
  }

  if (success) {
    Toaster.success(
      context: context,
      title: 'Миграция завершена',
      description: 'Backup создан, хранилище успешно мигрировано и открыто.',
    );
    await onOpened?.call();
    return true;
  }

  final state = await ref.read(mainStoreProvider.future);
  if (!context.mounted) {
    return true;
  }

  Toaster.error(
    context: context,
    title: 'Миграция не выполнена',
    description: state.error?.message ?? 'Не удалось выполнить миграцию.',
  );
  return true;
}

String _buildMigrationDescription(AppError? error) {
  final data = error?.data ?? const <String, dynamic>{};
  final currentAppVersion = data['currentAppVersion'];
  final storeAppVersion = data['storeAppVersion'];
  final currentSchemaVersion = data['currentSchemaVersion'];
  final storeSchemaVersion = data['storeSchemaVersion'];
  final currentManifestVersion = data['currentManifestVersion'];
  final storeManifestVersion = data['storeManifestVersion'];

  return <String>[
    'Хранилище было подготовлено для более старой версии приложения.',
    '',
    'Перед открытием будет создан backup, после чего приложение попробует выполнить миграцию и открыть store.',
    '',
    'Версия приложения: $storeAppVersion -> $currentAppVersion',
    'Версия схемы данных: $storeSchemaVersion -> $currentSchemaVersion',
    'Версия manifest: $storeManifestVersion -> $currentManifestVersion',
  ].join('\n');
}
