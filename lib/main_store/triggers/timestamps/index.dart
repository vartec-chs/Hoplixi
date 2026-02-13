/// Экспорт всех SQL триггеров для управления временными метками.
///
/// Этот файл экспортирует все триггеры временных меток для удобного импорта.
library;

import 'bank_cards_timestamps.dart';
import 'categories_timestamps.dart';
import 'document_pages_timestamps.dart';
import 'documents_timestamps.dart';
import 'files_timestamps.dart';
import 'icons_timestamps.dart';
import 'notes_timestamps.dart';
import 'otps_timestamps.dart';
import 'passwords_timestamps.dart';
import 'store_meta_timestamps.dart';
import 'tags_timestamps.dart';

export 'bank_cards_timestamps.dart';
export 'categories_timestamps.dart';
export 'document_pages_timestamps.dart';
export 'documents_timestamps.dart';
export 'files_timestamps.dart';
export 'icons_timestamps.dart';
export 'meta_touch_triggers.dart';
export 'notes_timestamps.dart';
export 'otps_timestamps.dart';
export 'passwords_timestamps.dart';
export 'store_meta_timestamps.dart';
export 'tags_timestamps.dart';

/// Все триггеры для установки временных меток при вставке.
final List<String> allInsertTimestampTriggers = [
  // Store Meta
  ...storeMetaInsertTimestampTriggers,
  // Passwords
  ...passwordsInsertTimestampTriggers,
  // OTPs
  ...otpsInsertTimestampTriggers,
  // Notes
  ...notesInsertTimestampTriggers,
  // Files
  ...filesInsertTimestampTriggers,
  // Bank Cards
  ...bankCardsInsertTimestampTriggers,
  // Documents
  ...documentsInsertTimestampTriggers,
  // Document Pages
  ...documentPagesInsertTimestampTriggers,
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
  // Passwords
  ...passwordsModifiedAtTriggers,
  // OTPs
  ...otpsModifiedAtTriggers,
  // Notes
  ...notesModifiedAtTriggers,
  // Files
  ...filesModifiedAtTriggers,
  // Bank Cards
  ...bankCardsModifiedAtTriggers,
  // Documents
  ...documentsModifiedAtTriggers,
  // Document Pages
  ...documentPagesModifiedAtTriggers,
  // Categories
  ...categoriesModifiedAtTriggers,
  // Tags
  ...tagsModifiedAtTriggers,
  // Icons
  ...iconsModifiedAtTriggers,
];

/// Все операторы для удаления триггеров временных меток.
final List<String> allTimestampDropTriggers = [
  // Store Meta
  ...storeMetaTimestampDropTriggers,
  // Passwords
  ...passwordsTimestampDropTriggers,
  // OTPs
  ...otpsTimestampDropTriggers,
  // Notes
  ...notesTimestampDropTriggers,
  // Files
  ...filesTimestampDropTriggers,
  // Bank Cards
  ...bankCardsTimestampDropTriggers,
  // Documents
  ...documentsTimestampDropTriggers,
  // Document Pages
  ...documentPagesTimestampDropTriggers,
  // Categories
  ...categoriesTimestampDropTriggers,
  // Tags
  ...tagsTimestampDropTriggers,
  // Icons
  ...iconsTimestampDropTriggers,
];
