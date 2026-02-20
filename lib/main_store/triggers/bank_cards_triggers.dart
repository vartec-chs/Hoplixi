/// SQL триггеры для записи истории изменений банковских карт.
///
/// Триггеры срабатывают на таблице `vault_items` (для строк с type = 'bankCard')
/// и вставляют записи в `vault_item_history` + `bank_card_history`.
const List<String> bankCardsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении банковской карты
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
  'DROP TRIGGER IF EXISTS bank_card_delete_history;',
];
