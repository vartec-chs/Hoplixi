/// Экспорт всех SQL триггеров для управления временными метками.
///
/// Этот файл экспортирует все триггеры временных меток для удобного импорта.
library;

import 'categories_timestamps.dart';
import 'document_pages_timestamps.dart';
import 'document_versions_timestamps.dart';
import 'icons_timestamps.dart';
import 'passwords_timestamps.dart';
import 'store_meta_timestamps.dart';
import 'tags_timestamps.dart';

export 'categories_timestamps.dart';
export 'document_pages_timestamps.dart';
export 'document_versions_timestamps.dart';
export 'icons_timestamps.dart';
export 'meta_touch_triggers.dart';
export 'passwords_timestamps.dart';
export 'store_meta_timestamps.dart';
export 'tags_timestamps.dart';

/// Все триггеры для установки временных меток при вставке.
///
/// Включает единый триггер для vault_items (заменяет отдельные триггеры
/// для passwords, notes, bank_cards, otps, files, documents).
final List<String> allInsertTimestampTriggers = [
  // Store Meta
  ...storeMetaInsertTimestampTriggers,
  // Vault Items (все сущности: passwords, notes, otps, bank cards, files, docs)
  ...vaultItemsInsertTimestampTriggers,
  // Document Pages
  ...documentPagesInsertTimestampTriggers,
  // Document Versions
  ...documentVersionsInsertTimestampTriggers,
  // Categories
  ...categoriesInsertTimestampTriggers,
  // Tags
  ...tagsInsertTimestampTriggers,
  // Icons
  ...iconsInsertTimestampTriggers,
];

/// Все триггеры для обновления modified_at.
final List<String> allModifiedAtTriggers = [
  // Store Meta
  ...storeMetaModifiedAtTriggers,
  // Vault Items (все сущности)
  ...vaultItemsModifiedAtTriggers,
  // Document Pages
  ...documentPagesModifiedAtTriggers,
  // Document Versions
  ...documentVersionsModifiedAtTriggers,
  // Categories
  ...categoriesModifiedAtTriggers,
  // Tags
  ...tagsModifiedAtTriggers,
  // Icons
  ...iconsModifiedAtTriggers,
];

/// Все операторы для удаления триггеров временных меток.
///
/// Включает DROP для старых триггеров (из предыдущей схемы) для корректной
/// миграции, а также DROP для новых триггеров.
final List<String> allTimestampDropTriggers = [
  // Store Meta
  ...storeMetaTimestampDropTriggers,
  // Vault Items (новые)
  ...vaultItemsTimestampDropTriggers,
  // Устаревшие триггеры старой схемы (для миграции)

  // Document Pages
  ...documentPagesTimestampDropTriggers,
  // Document Versions
  ...documentVersionsTimestampDropTriggers,
  // Categories
  ...categoriesTimestampDropTriggers,
  // Tags
  ...tagsTimestampDropTriggers,
  // Icons
  ...iconsTimestampDropTriggers,
];
