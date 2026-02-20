/// SQL триггеры для записи истории изменений банковских карт.
///
/// Триггеры срабатывают на таблице `vault_items` (для строк с type = 'bankCard')
/// и вставляют записи в `vault_item_history` + `bank_card_history`.
/// Дополнительный триггер на `bank_card_items` отслеживает изменения
/// специфичных полей: cardholder_name, card_number, card_type, card_network,
/// expiry_month, expiry_year, cvv, bank_name, account_number, routing_number.
const List<String> bankCardsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении общих полей карты
  '''
    CREATE TRIGGER IF NOT EXISTS bank_card_update_history
    AFTER UPDATE ON vault_items
    FOR EACH ROW
    WHEN NEW.type = 'bankCard' AND OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.description IS NOT NEW.description OR
      OLD.category_id IS NOT NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned OR
      OLD.recent_score IS NOT NEW.recent_score OR
      OLD.last_used_at IS NOT NEW.last_used_at
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id,
        item_id,
        type,
        name,
        description,
        category_id,
        category_name,
        action,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        OLD.type,
        OLD.name,
        OLD.description,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        'modified',
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_deleted,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')
      );
      INSERT INTO bank_card_history (
        history_id,
        cardholder_name,
        card_number,
        card_type,
        card_network,
        expiry_month,
        expiry_year,
        cvv,
        bank_name,
        account_number,
        routing_number
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        bci.cardholder_name,
        bci.card_number,
        bci.card_type,
        bci.card_network,
        bci.expiry_month,
        bci.expiry_year,
        bci.cvv,
        bci.bank_name,
        bci.account_number,
        bci.routing_number
      FROM bank_card_items bci
      WHERE bci.item_id = OLD.id;
    END;
  ''',

  // Триггер для записи истории при изменении специфичных полей карты
  '''
    CREATE TRIGGER IF NOT EXISTS bank_card_fields_update_history
    AFTER UPDATE ON bank_card_items
    FOR EACH ROW
    WHEN (
      OLD.cardholder_name != NEW.cardholder_name OR
      OLD.card_number != NEW.card_number OR
      OLD.card_type IS NOT NEW.card_type OR
      OLD.card_network IS NOT NEW.card_network OR
      OLD.expiry_month != NEW.expiry_month OR
      OLD.expiry_year != NEW.expiry_year OR
      OLD.cvv IS NOT NEW.cvv OR
      OLD.bank_name IS NOT NEW.bank_name OR
      OLD.account_number IS NOT NEW.account_number OR
      OLD.routing_number IS NOT NEW.routing_number
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id,
        item_id,
        type,
        name,
        description,
        category_id,
        category_name,
        action,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        action_at
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        v.id,
        v.type,
        v.name,
        v.description,
        v.category_id,
        (SELECT name FROM categories WHERE id = v.category_id),
        'modified',
        v.used_count,
        v.is_favorite,
        v.is_archived,
        v.is_pinned,
        v.is_deleted,
        v.recent_score,
        v.last_used_at,
        v.created_at,
        v.modified_at,
        strftime('%s','now')
      FROM vault_items v
      WHERE v.id = OLD.item_id;

      INSERT INTO bank_card_history (
        history_id,
        cardholder_name,
        card_number,
        card_type,
        card_network,
        expiry_month,
        expiry_year,
        cvv,
        bank_name,
        account_number,
        routing_number
      ) VALUES (
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        OLD.cardholder_name,
        OLD.card_number,
        OLD.card_type,
        OLD.card_network,
        OLD.expiry_month,
        OLD.expiry_year,
        OLD.cvv,
        OLD.bank_name,
        OLD.account_number,
        OLD.routing_number
      );
    END;
  ''',

  // Триггер для записи истории при удалении банковской карты
  '''
    CREATE TRIGGER IF NOT EXISTS bank_card_delete_history
    BEFORE DELETE ON vault_items
    FOR EACH ROW
    WHEN OLD.type = 'bankCard' AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id,
        item_id,
        type,
        name,
        description,
        category_id,
        category_name,
        action,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        recent_score,
        last_used_at,
        original_created_at,
        original_modified_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        OLD.type,
        OLD.name,
        OLD.description,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        'deleted',
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_deleted,
        OLD.recent_score,
        OLD.last_used_at,
        OLD.created_at,
        OLD.modified_at,
        strftime('%s','now')
      );
      INSERT INTO bank_card_history (
        history_id,
        cardholder_name,
        card_number,
        card_type,
        card_network,
        expiry_month,
        expiry_year,
        cvv,
        bank_name,
        account_number,
        routing_number
      )
      SELECT
        (SELECT id FROM vault_item_history
         WHERE item_id = OLD.id ORDER BY action_at DESC LIMIT 1),
        bci.cardholder_name,
        bci.card_number,
        bci.card_type,
        bci.card_network,
        bci.expiry_month,
        bci.expiry_year,
        bci.cvv,
        bci.bank_name,
        bci.account_number,
        bci.routing_number
      FROM bank_card_items bci
      WHERE bci.item_id = OLD.id;
    END;
  ''',
];

/// Операторы для удаления триггеров истории банковских карт.
const List<String> bankCardsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS bank_card_update_history;',
  'DROP TRIGGER IF EXISTS bank_card_fields_update_history;',
  'DROP TRIGGER IF EXISTS bank_card_delete_history;',
];
