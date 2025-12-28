/// SQL триггеры для записи истории изменений банковских карт.
///
/// Эти триггеры автоматически создают записи в таблице `bank_cards_history`
/// при обновлении или удалении банковских карт.
const List<String> bankCardsHistoryCreateTriggers = [
  // Триггер для записи истории при обновлении банковской карты
  '''
    CREATE TRIGGER IF NOT EXISTS bank_card_update_history
    AFTER UPDATE ON bank_cards
    FOR EACH ROW
    WHEN OLD.id = NEW.id AND (
      OLD.name != NEW.name OR
      OLD.cardholder_name != NEW.cardholder_name OR
      OLD.card_number != NEW.card_number OR
      OLD.card_type != NEW.card_type OR
      OLD.card_network != NEW.card_network OR
      OLD.expiry_month != NEW.expiry_month OR
      OLD.expiry_year != NEW.expiry_year OR
      OLD.cvv != NEW.cvv OR
      OLD.bank_name != NEW.bank_name OR
      OLD.account_number != NEW.account_number OR
      OLD.routing_number != NEW.routing_number OR
      OLD.description != NEW.description OR
      OLD.notes != NEW.notes OR
      OLD.category_id != NEW.category_id OR
      OLD.is_favorite != NEW.is_favorite OR
      OLD.is_deleted != NEW.is_deleted OR
      OLD.is_archived != NEW.is_archived OR
      OLD.is_pinned != NEW.is_pinned
    )
    BEGIN
      INSERT INTO bank_cards_history (
        id,
        original_card_id,
        action,
        name,
        cardholder_name,
        card_number,
        card_type,
        card_network,
        expiry_month,
        expiry_year,
        cvv,
        bank_name,
        account_number,
        routing_number,
        description,
        notes,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        original_created_at,
        original_modified_at,
        original_last_accessed_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'modified',
        OLD.name,
        OLD.cardholder_name,
        OLD.card_number,
        OLD.card_type,
        OLD.card_network,
        OLD.expiry_month,
        OLD.expiry_year,
        OLD.cvv,
        OLD.bank_name,
        OLD.account_number,
        OLD.routing_number,
        OLD.description,
        OLD.notes,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_deleted,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_accessed_at,
        strftime('%s','now')  
      );
    END;
  ''',
  // Триггер для записи истории при удалении банковской карты
  '''
    CREATE TRIGGER IF NOT EXISTS bank_card_delete_history
    BEFORE DELETE ON bank_cards
    FOR EACH ROW
    BEGIN
      INSERT INTO bank_cards_history (
        id,
        original_card_id,
        action,
        name,
        cardholder_name,
        card_number,
        card_type,
        card_network,
        expiry_month,
        expiry_year,
        cvv,
        bank_name,
        account_number,
        routing_number,
        description,
        notes,
        category_id,
        category_name,
        used_count,
        is_favorite,
        is_archived,
        is_pinned,
        is_deleted,
        original_created_at,
        original_modified_at,
        original_last_accessed_at,
        action_at
      ) VALUES (
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('ab89',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        OLD.id,
        'deleted',
        OLD.name,
        OLD.cardholder_name,
        OLD.card_number,
        OLD.card_type,
        OLD.card_network,
        OLD.expiry_month,
        OLD.expiry_year,
        OLD.cvv,
        OLD.bank_name,
        OLD.account_number,
        OLD.routing_number,
        OLD.description,
        OLD.notes,
        OLD.category_id,
        (SELECT name FROM categories WHERE id = OLD.category_id),
        OLD.used_count,
        OLD.is_favorite,
        OLD.is_archived,
        OLD.is_pinned,
        OLD.is_deleted,
        OLD.created_at,
        OLD.modified_at,
        OLD.last_accessed_at,
        strftime('%s','now')  
      );
    END;
  ''',
];

/// Операторы для удаления триггеров истории банковских карт.
const List<String> bankCardsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS bank_card_update_history;',
  'DROP TRIGGER IF EXISTS bank_card_delete_history;',
];
