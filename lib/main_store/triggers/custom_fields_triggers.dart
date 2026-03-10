/// SQL-триггеры для записи истории изменений кастомных полей.
///
/// Три триггера на таблице `vault_item_custom_fields`:
/// - AFTER INSERT  — поле добавлено: snapshot всех текущих полей
/// - AFTER UPDATE  — поле изменено: snapshot всех текущих полей (новые значения)
/// - BEFORE DELETE — поле удалено: snapshot всех текущих полей включая удаляемое
///
/// В каждом случае сначала создаётся запись в `vault_item_history`
/// (snapshot vault_items, action = 'modified'), а затем — по одной
/// строке в `vault_item_custom_fields_history` для каждого кастомного поля.
///
/// Триггер BEFORE DELETE защищён условием:
/// `(SELECT COUNT(*) FROM vault_items WHERE id = OLD.item_id) > 0` —
/// это предотвращает создание сирот при каскадном удалении, когда
/// родительская строка vault_items уже была удалена.

// UUID v4 helper, используемый во всех trigger INSERT-ах
const _uuid =
    "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || "
    "substr(lower(hex(randomblob(2))),2) || '-' || "
    "substr('ab89', abs(random()) % 4 + 1, 1) || "
    "substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6)))";

const List<String> customFieldsHistoryCreateTriggers = [
  // ── AFTER INSERT ─────────────────────────────────────────────────────────
  // Срабатывает после добавления нового кастомного поля.
  // Снимок включает ВСЕ поля (включая новое).
  r'''
    CREATE TRIGGER IF NOT EXISTS custom_field_insert_history
    AFTER INSERT ON vault_item_custom_fields
    FOR EACH ROW
    WHEN COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' ||
          substr(lower(hex(randomblob(2))),2) || '-' ||
          substr('ab89', abs(random()) % 4 + 1, 1) ||
          substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        v.id, v.type, v.name, v.description, v.category_id,
        (SELECT name FROM categories WHERE id = v.category_id),
        'modified',
        v.used_count, v.is_favorite, v.is_archived, v.is_pinned, v.is_deleted,
        v.recent_score, v.last_used_at, v.created_at, v.modified_at,
        strftime('%s', 'now')
      FROM vault_items v WHERE v.id = NEW.item_id;

      INSERT INTO vault_item_custom_fields_history (
        id, history_id, field_id, label, value, field_type, sort_order
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' ||
          substr(lower(hex(randomblob(2))),2) || '-' ||
          substr('ab89', abs(random()) % 4 + 1, 1) ||
          substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        (SELECT id FROM vault_item_history
          WHERE item_id = NEW.item_id ORDER BY action_at DESC LIMIT 1),
        cf.id, cf.label, cf.value, cf.field_type, cf.sort_order
      FROM vault_item_custom_fields cf
      WHERE cf.item_id = NEW.item_id;
    END;
  ''',

  // ── AFTER UPDATE ─────────────────────────────────────────────────────────
  // Срабатывает после изменения любого поля кастомного поля.
  // Снимок включает текущее состояние ВСЕХ полей (включая обновлённое значение).
  r'''
    CREATE TRIGGER IF NOT EXISTS custom_field_update_history
    AFTER UPDATE ON vault_item_custom_fields
    FOR EACH ROW
    WHEN (
      OLD.label != NEW.label OR
      OLD.value IS NOT NEW.value OR
      OLD.field_type != NEW.field_type OR
      OLD.sort_order != NEW.sort_order
    ) AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' ||
          substr(lower(hex(randomblob(2))),2) || '-' ||
          substr('ab89', abs(random()) % 4 + 1, 1) ||
          substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        v.id, v.type, v.name, v.description, v.category_id,
        (SELECT name FROM categories WHERE id = v.category_id),
        'modified',
        v.used_count, v.is_favorite, v.is_archived, v.is_pinned, v.is_deleted,
        v.recent_score, v.last_used_at, v.created_at, v.modified_at,
        strftime('%s', 'now')
      FROM vault_items v WHERE v.id = NEW.item_id;

      INSERT INTO vault_item_custom_fields_history (
        id, history_id, field_id, label, value, field_type, sort_order
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' ||
          substr(lower(hex(randomblob(2))),2) || '-' ||
          substr('ab89', abs(random()) % 4 + 1, 1) ||
          substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        (SELECT id FROM vault_item_history
          WHERE item_id = NEW.item_id ORDER BY action_at DESC LIMIT 1),
        cf.id, cf.label, cf.value, cf.field_type, cf.sort_order
      FROM vault_item_custom_fields cf
      WHERE cf.item_id = NEW.item_id;
    END;
  ''',

  // ── BEFORE DELETE ─────────────────────────────────────────────────────────
  // Срабатывает ПЕРЕД удалением кастомного поля.
  // Снимок включает ВСЕ текущие поля (включая удаляемое, т.к. оно ещё в таблице).
  //
  // Условие `(SELECT COUNT(*) FROM vault_items WHERE id = OLD.item_id) > 0`
  // предотвращает срабатывание при каскадном DELETE от vault_items:
  // на момент BEFORE DELETE на vault_item_custom_fields родительская строка
  // vault_items уже удалена, и COUNT вернёт 0.
  r'''
    CREATE TRIGGER IF NOT EXISTS custom_field_delete_history
    BEFORE DELETE ON vault_item_custom_fields
    FOR EACH ROW
    WHEN (SELECT COUNT(*) FROM vault_items WHERE id = OLD.item_id) > 0
      AND COALESCE((SELECT value FROM store_settings WHERE key = 'history_enabled'), 'true') = 'true'
    BEGIN
      INSERT INTO vault_item_history (
        id, item_id, type, name, description, category_id, category_name,
        action, used_count, is_favorite, is_archived, is_pinned, is_deleted,
        recent_score, last_used_at, original_created_at, original_modified_at, action_at
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' ||
          substr(lower(hex(randomblob(2))),2) || '-' ||
          substr('ab89', abs(random()) % 4 + 1, 1) ||
          substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        v.id, v.type, v.name, v.description, v.category_id,
        (SELECT name FROM categories WHERE id = v.category_id),
        'modified',
        v.used_count, v.is_favorite, v.is_archived, v.is_pinned, v.is_deleted,
        v.recent_score, v.last_used_at, v.created_at, v.modified_at,
        strftime('%s', 'now')
      FROM vault_items v WHERE v.id = OLD.item_id;

      INSERT INTO vault_item_custom_fields_history (
        id, history_id, field_id, label, value, field_type, sort_order
      )
      SELECT
        lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' ||
          substr(lower(hex(randomblob(2))),2) || '-' ||
          substr('ab89', abs(random()) % 4 + 1, 1) ||
          substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6))),
        (SELECT id FROM vault_item_history
          WHERE item_id = OLD.item_id ORDER BY action_at DESC LIMIT 1),
        cf.id, cf.label, cf.value, cf.field_type, cf.sort_order
      FROM vault_item_custom_fields cf
      WHERE cf.item_id = OLD.item_id;
    END;
  ''',
];

const List<String> customFieldsHistoryDropTriggers = [
  'DROP TRIGGER IF EXISTS custom_field_insert_history;',
  'DROP TRIGGER IF EXISTS custom_field_update_history;',
  'DROP TRIGGER IF EXISTS custom_field_delete_history;',
];
