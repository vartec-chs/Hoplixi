/// SQL триггеры для обновления store_meta.modified_at при изменениях в таблицах.
///
/// Эти триггеры автоматически обновляют `modified_at` в таблице `store_meta`
/// при добавлении, изменении или удалении записей в любой отслеживаемой таблице.
/// Это позволяет отслеживать последнее изменение во всей базе данных.

/// Триггеры для обновления store_meta при изменениях в таблице passwords.
const List<String> passwordsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_insert
    AFTER INSERT ON passwords
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_update
    AFTER UPDATE ON passwords
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_passwords_delete
    AFTER DELETE ON passwords
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице otps.
const List<String> otpsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_insert
    AFTER INSERT ON otps
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_update
    AFTER UPDATE ON otps
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_otps_delete
    AFTER DELETE ON otps
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице notes.
const List<String> notesMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_insert
    AFTER INSERT ON notes
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_update
    AFTER UPDATE ON notes
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_notes_delete
    AFTER DELETE ON notes
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице files.
const List<String> filesMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_files_insert
    AFTER INSERT ON files
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_files_update
    AFTER UPDATE ON files
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_files_delete
    AFTER DELETE ON files
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице bank_cards.
const List<String> bankCardsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_bank_cards_insert
    AFTER INSERT ON bank_cards
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_bank_cards_update
    AFTER UPDATE ON bank_cards
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_bank_cards_delete
    AFTER DELETE ON bank_cards
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

/// Триггеры для обновления store_meta при изменениях в таблице password_tags.
const List<String> passwordTagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_tags_insert
    AFTER INSERT ON password_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_password_tags_delete
    AFTER DELETE ON password_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице otp_tags.
const List<String> otpTagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_tags_insert
    AFTER INSERT ON otp_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_otp_tags_delete
    AFTER DELETE ON otp_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице note_tags.
const List<String> noteTagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_tags_insert
    AFTER INSERT ON notes_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_note_tags_delete
    AFTER DELETE ON notes_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице file_tags.
const List<String> fileTagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_file_tags_insert
    AFTER INSERT ON files_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_file_tags_delete
    AFTER DELETE ON files_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Триггеры для обновления store_meta при изменениях в таблице bank_cards_tags.
const List<String> bankCardsTagsMetaTouchTriggers = [
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_bank_cards_tags_insert
    AFTER INSERT ON bank_cards_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
  '''
    CREATE TRIGGER IF NOT EXISTS touch_meta_on_bank_cards_tags_delete
    AFTER DELETE ON bank_cards_tags
    BEGIN
      UPDATE store_meta
      SET modified_at = strftime('%s','now')  
      WHERE id = (SELECT id FROM store_meta ORDER BY created_at LIMIT 1);
    END;
  ''',
];

/// Все триггеры для обновления store_meta при изменениях.
const List<String> allMetaTouchCreateTriggers = [
  // Основные таблицы
  ...passwordsMetaTouchTriggers,
  ...otpsMetaTouchTriggers,
  ...notesMetaTouchTriggers,
  ...filesMetaTouchTriggers,
  ...bankCardsMetaTouchTriggers,
  ...categoriesMetaTouchTriggers,
  ...tagsMetaTouchTriggers,
  ...iconsMetaTouchTriggers,
  ...noteLinksMetaTouchTriggers,
  // Связующие таблицы тегов
  ...passwordTagsMetaTouchTriggers,
  ...otpTagsMetaTouchTriggers,
  ...noteTagsMetaTouchTriggers,
  ...fileTagsMetaTouchTriggers,
  ...bankCardsTagsMetaTouchTriggers,
];

/// Операторы для удаления триггеров обновления store_meta.
const List<String> allMetaTouchDropTriggers = [
  // Passwords
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_passwords_delete;',
  // OTPs
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otps_delete;',
  // Notes
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_notes_delete;',
  // Files
  'DROP TRIGGER IF EXISTS touch_meta_on_files_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_files_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_files_delete;',
  // Bank Cards
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_delete;',
  // Categories
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_categories_delete;',
  // Tags
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_tags_delete;',
  // Icons
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_icons_delete;',
  // Note Links
  'DROP TRIGGER IF EXISTS touch_meta_on_note_links_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_links_update;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_links_delete;',
  // Password Tags
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_password_tags_delete;',
  // OTP Tags
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_otp_tags_delete;',
  // Note Tags
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_note_tags_delete;',
  // File Tags
  'DROP TRIGGER IF EXISTS touch_meta_on_file_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_file_tags_delete;',
  // Bank Cards Tags
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_tags_insert;',
  'DROP TRIGGER IF EXISTS touch_meta_on_bank_cards_tags_delete;',
];
