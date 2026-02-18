/// SQL триггеры для обновления store_meta.modified_at при изменениях в таблицах.
///
/// Эти триггеры автоматически обновляют `modified_at` в таблице `store_meta`
/// при добавлении, изменении или удалении записей в любой отслеживаемой таблице.
/// Это позволяет отслеживать последнее изменение во всей базе данных.
library;

/// Триггеры для обновления store_meta при изменениях в таблице vault_items.
///
/// Заменяет отдельные триггеры для passwords, notes, bank_cards, otps,
/// files, documents — теперь все сущности хранятся в vault_items.
const List<String> vaultItemsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_vault_items_insert
    AFTER INSERT ON vault_items
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_vault_items_update
    AFTER UPDATE ON vault_items
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_vault_items_delete
    AFTER DELETE ON vault_items
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице item_tags.
///
/// Заменяет отдельные триггеры для password_tags, otp_tags, notes_tags,
/// files_tags, bank_cards_tags — теперь все теги хранятся в item_tags.
const List<String> itemTagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_item_tags_insert
    AFTER INSERT ON item_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_item_tags_delete
    AFTER DELETE ON item_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице categories.
const List<String> categoriesMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_insert
    AFTER INSERT ON categories
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_update
    AFTER UPDATE ON categories
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_categories_delete
    AFTER DELETE ON categories
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице tags.
const List<String> tagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_insert
    AFTER INSERT ON tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_update
    AFTER UPDATE ON tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_tags_delete
    AFTER DELETE ON tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице icons.
const List<String> iconsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_insert
    AFTER INSERT ON icons
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_update
    AFTER UPDATE ON icons
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_icons_delete
    AFTER DELETE ON icons
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице note_links.
const List<String> noteLinksMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_links_insert
    AFTER INSERT ON note_links
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_links_update
    AFTER UPDATE ON note_links
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_links_delete
    AFTER DELETE ON note_links
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Все триггеры для обновления store_meta при изменениях.
const List<String> allMetaTouchCreateTriggers = [
  // Vault Items (все сущности: passwords, notes, otps, bank cards, files, docs)
  ...vaultItemsMetaTouchTriggers,
  // Item Tags (единая таблица тегов)
  ...itemTagsMetaTouchTriggers,
  // Вспомогательные таблицы
  ...categoriesMetaTouchTriggers,
  ...tagsMetaTouchTriggers,
  ...iconsMetaTouchTriggers,
  ...noteLinksMetaTouchTriggers,
];

/// Операторы для удаления триггеров обновления store_meta.
///
/// Включает DROP для старых триггеров (из предыдущей схемы) для корректной
/// миграции, а также DROP для новых триггеров.
const List<String> allMetaTouchDropTriggers = [
  // Vault Items (новые)
  'DROP TRIGGER IF EXISTS touch_meta_on_vault_items_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_vault_items_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_vault_items_delete;',
  // Item Tags (новые)
  'DROP TRIGGER IF EXISTS touch_meta_on_item_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_item_tags_delete;',
  // Устаревшие триггеры старой схемы (для миграции)
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_files_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_files_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_files_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_documents_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_documents_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_documents_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_file_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_file_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_tags_delete;',
  // Текущие вспомогательные таблицы
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_delete;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_links_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_links_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_links_delete;',
];
