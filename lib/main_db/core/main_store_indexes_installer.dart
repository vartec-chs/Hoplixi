import 'package:hoplixi/core/logger/app_logger.dart';

typedef SqlStatementExecutor = Future<void> Function(String sql);

const _mainStoreIndexes = [
  // --- vault_items ---
  // Покрывает обязательный WHERE (is_deleted, is_archived) + дефолтный ORDER BY
  'CREATE INDEX IF NOT EXISTS idx_vi_active_pinned_modified '
      'ON vault_items (is_deleted, is_archived, is_pinned DESC, modified_at DESC)',
  // Фильтрация по категории
  'CREATE INDEX IF NOT EXISTS idx_vi_active_category '
      'ON vault_items (is_deleted, is_archived, category_id)',
  // Фильтрация избранного
  'CREATE INDEX IF NOT EXISTS idx_vi_active_favorite '
      'ON vault_items (is_deleted, is_archived, is_favorite)',
  // Сортировка по дате создания
  'CREATE INDEX IF NOT EXISTS idx_vi_active_created_at '
      'ON vault_items (is_deleted, is_archived, created_at)',
  // Сортировка по последнему использованию
  'CREATE INDEX IF NOT EXISTS idx_vi_active_last_used '
      'ON vault_items (is_deleted, is_archived, last_used_at)',

  // --- item_tags ---
  // Обратный поиск всех элементов по тегу (EXISTS-subquery в filter DAO).
  // Поиск по itemId покрыт левым префиксом составного PK (itemId, tagId).
  'CREATE INDEX IF NOT EXISTS idx_item_tags_tag_id '
      'ON item_tags (tag_id)',

  // --- password_items ---
  // WHERE expire_at IS NOT NULL ORDER BY expire_at ASC (поиск истекающих паролей)
  'CREATE INDEX IF NOT EXISTS idx_password_items_expire_at '
      'ON password_items (expire_at) WHERE expire_at IS NOT NULL',

  // --- api_key_items ---
  // Для сортировки/фильтрации по истечению и сервису
  'CREATE INDEX IF NOT EXISTS idx_api_key_items_expires_at '
      'ON api_key_items (expires_at) WHERE expires_at IS NOT NULL',
  'CREATE INDEX IF NOT EXISTS idx_api_key_items_service '
      'ON api_key_items (service)',

  // --- ssh_key_items ---
  'CREATE INDEX IF NOT EXISTS idx_ssh_key_items_key_type '
      'ON ssh_key_items (key_type)',
  'CREATE INDEX IF NOT EXISTS idx_ssh_key_items_fingerprint '
      'ON ssh_key_items (fingerprint)',

  // --- certificate_items ---
  'CREATE INDEX IF NOT EXISTS idx_certificate_items_issuer '
      'ON certificate_items (issuer)',
  'CREATE INDEX IF NOT EXISTS idx_certificate_items_fingerprint '
      'ON certificate_items (fingerprint)',
  'CREATE INDEX IF NOT EXISTS idx_certificate_items_valid_to '
      'ON certificate_items (valid_to) WHERE valid_to IS NOT NULL',

  // --- crypto_wallet_items ---
  'CREATE INDEX IF NOT EXISTS idx_crypto_wallet_items_wallet_type '
      'ON crypto_wallet_items (wallet_type)',
  'CREATE INDEX IF NOT EXISTS idx_crypto_wallet_items_network '
      'ON crypto_wallet_items (network)',

  // --- wifi_items ---
  'CREATE INDEX IF NOT EXISTS idx_wifi_items_security_type '
      'ON wifi_items (security)',
  'CREATE INDEX IF NOT EXISTS idx_wifi_items_ssid '
      'ON wifi_items (ssid)',

  // --- identity_items ---
  'CREATE INDEX IF NOT EXISTS idx_identity_items_id_type '
      'ON identity_items (id_type)',
  'CREATE INDEX IF NOT EXISTS idx_identity_items_id_number '
      'ON identity_items (id_number)',
  'CREATE INDEX IF NOT EXISTS idx_identity_items_expiry_date '
      'ON identity_items (expiry_date) WHERE expiry_date IS NOT NULL',

  // --- license_key_items ---
  'CREATE INDEX IF NOT EXISTS idx_license_key_items_product '
      'ON license_key_items (product)',
  'CREATE INDEX IF NOT EXISTS idx_license_key_items_license_type '
      'ON license_key_items (license_type)',
  'CREATE INDEX IF NOT EXISTS idx_license_key_items_order_id '
      'ON license_key_items (order_id)',
  'CREATE INDEX IF NOT EXISTS idx_license_key_items_expires_at '
      'ON license_key_items (expires_at) WHERE expires_at IS NOT NULL',

  // --- vault_item_history ---
  // WHERE item_id = ? AND type = ? ORDER BY action_at DESC
  'CREATE INDEX IF NOT EXISTS idx_vih_item_type_action_at '
      'ON vault_item_history (item_id, type, action_at DESC)',

  // --- item_links ---
  // Индекс на target_item_id ускоряет входящие item -> item ссылки.
  'CREATE INDEX IF NOT EXISTS idx_item_links_target '
      'ON item_links (target_item_id)',

  // --- document_pages ---
  // Live-указатель текущей версии страницы.
  'CREATE INDEX IF NOT EXISTS idx_doc_pages_current_version_page '
      'ON document_pages (current_version_page_id)',

  // --- document_versions ---
  // WHERE document_id = ? AND is_current = 1 (получение активной версии).
  'CREATE INDEX IF NOT EXISTS idx_doc_versions_current '
      'ON document_versions (document_id, is_current)',

  // --- document_version_pages ---
  // WHERE version_id = ? ORDER BY page_number ASC.
  'CREATE INDEX IF NOT EXISTS idx_doc_version_pages_version_page '
      'ON document_version_pages (version_id, page_number)',

  // --- file_metadata_history ---
  // Быстрый поиск snapshot по исходной metadata-записи.
  'CREATE INDEX IF NOT EXISTS idx_fmh_metadata_id '
      'ON file_metadata_history (metadata_id)',

  // --- categories ---
  // WHERE type IN (...) в category DAO
  'CREATE INDEX IF NOT EXISTS idx_categories_type '
      'ON categories (type)',

  // Фильтрация по родительской категории (иерархия)
  'CREATE INDEX IF NOT EXISTS idx_categories_parent_id '
      'ON categories (parent_id)',

  // --- tags ---
  // WHERE type IN (...) в tag DAO
  'CREATE INDEX IF NOT EXISTS idx_tags_type '
      'ON tags (type)',
];

Future<void> installMainStoreIndexes({
  required SqlStatementExecutor executeStatement,
  String logTag = 'MainStore',
}) async {
  logInfo('Installing indexes...', tag: logTag);

  try {
    for (final sql in _mainStoreIndexes) {
      await executeStatement(sql);
    }

    logInfo('All indexes installed successfully', tag: logTag);
  } catch (e, stackTrace) {
    logError(
      'Failed to install indexes',
      error: e,
      stackTrace: stackTrace,
      tag: logTag,
    );
    rethrow;
  }
}
