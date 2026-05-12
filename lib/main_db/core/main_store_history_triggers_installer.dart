import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/tables/document/document_pages.dart';
import 'package:hoplixi/main_db/core/triggers/index.dart';

typedef SqlStatementExecutor = Future<void> Function(String sql);

Future<void> installMainStoreHistoryTriggers({
  required SqlStatementExecutor executeStatement,
  String logTag = 'MainStore',
}) async {
  logInfo('Installing triggers...', tag: logTag);

  try {
    // Удаляем старые триггеры истории (если есть)
    for (final drop in [
      ...passwordsHistoryDropTriggers,
      ...apiKeysHistoryDropTriggers,
      ...sshKeysHistoryDropTriggers,
      ...certificatesHistoryDropTriggers,
      ...contactsHistoryDropTriggers,
      ...cryptoWalletsHistoryDropTriggers,
      ...wifisHistoryDropTriggers,
      ...identitiesHistoryDropTriggers,
      ...licenseKeysHistoryDropTriggers,
      ...recoveryCodesHistoryDropTriggers,
      ...recoveryCodesCacheDropTriggers,
      ...otpsHistoryDropTriggers,
      ...notesHistoryDropTriggers,
      ...filesHistoryDropTriggers,
      ...bankCardsHistoryDropTriggers,
      ...documentsDropTriggers,
      ...documentPagesTableDropTriggers,
      ...loyaltyCardsHistoryDropTriggers,
      ...customFieldsHistoryDropTriggers,
    ]) {
      await executeStatement(drop);
    }

    // Удаляем старые триггеры временных меток (если есть)
    for (final drop in allTimestampDropTriggers) {
      await executeStatement(drop);
    }

    // Удаляем старые триггеры обновления store_meta (если есть)
    for (final drop in allMetaTouchDropTriggers) {
      await executeStatement(drop);
    }

    // Создаём триггеры истории изменений
    for (final trigger in [
      ...passwordsHistoryCreateTriggers,
      ...apiKeysHistoryCreateTriggers,
      ...sshKeysHistoryCreateTriggers,
      ...certificatesHistoryCreateTriggers,
      ...contactsHistoryCreateTriggers,
      ...cryptoWalletsHistoryCreateTriggers,
      ...wifisHistoryCreateTriggers,
      ...identitiesHistoryCreateTriggers,
      ...licenseKeysHistoryCreateTriggers,
      ...recoveryCodesHistoryCreateTriggers,
      ...recoveryCodesCacheCreateTriggers,
      ...otpsHistoryCreateTriggers,
      ...notesHistoryCreateTriggers,
      ...filesHistoryCreateTriggers,
      ...bankCardsHistoryCreateTriggers,
      ...documentsHistoryCreateTriggers,
      ...documentsTriggers,
      ...documentPagesTableTriggers,
      ...loyaltyCardsHistoryCreateTriggers,
      ...customFieldsHistoryCreateTriggers,
    ]) {
      await executeStatement(trigger);
    }

    // Создаём триггеры для автоматической установки created_at
    for (final trigger in allInsertTimestampTriggers) {
      await executeStatement(trigger);
    }

    // Создаём триггеры для автоматического обновления modified_at
    for (final trigger in allModifiedAtTriggers) {
      await executeStatement(trigger);
    }

    // Создаём триггеры для обновления store_meta
    for (final trigger in allMetaTouchCreateTriggers) {
      await executeStatement(trigger);
    }

    logInfo('All triggers installed successfully', tag: logTag);
  } catch (e, stackTrace) {
    logError(
      'Failed to install triggers',
      error: e,
      stackTrace: stackTrace,
      tag: logTag,
    );
    rethrow;
  }
}
