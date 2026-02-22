import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/dao/api_key_dao.dart';
import 'package:hoplixi/main_store/dao/bank_card_dao.dart';
import 'package:hoplixi/main_store/dao/category_dao.dart';
import 'package:hoplixi/main_store/dao/certificate_dao.dart';
import 'package:hoplixi/main_store/dao/contact_dao.dart';
import 'package:hoplixi/main_store/dao/crypto_wallet_dao.dart';
import 'package:hoplixi/main_store/dao/document_dao.dart';
import 'package:hoplixi/main_store/dao/file_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/api_key_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/bank_card_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/certificate_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/contact_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/crypto_wallet_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/document_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/file_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/identity_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/license_key_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/note_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/otp_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/password_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/recovery_codes_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/ssh_key_history_dao.dart';
import 'package:hoplixi/main_store/dao/history_dao/wifi_history_dao.dart';
import 'package:hoplixi/main_store/dao/icon_dao.dart';
import 'package:hoplixi/main_store/dao/identity_dao.dart';
import 'package:hoplixi/main_store/dao/license_key_dao.dart';
import 'package:hoplixi/main_store/dao/note_dao.dart';
import 'package:hoplixi/main_store/dao/note_link_dao.dart';
import 'package:hoplixi/main_store/dao/otp_dao.dart';
import 'package:hoplixi/main_store/dao/password_dao.dart';
import 'package:hoplixi/main_store/dao/recovery_codes_dao.dart';
import 'package:hoplixi/main_store/dao/ssh_key_dao.dart';
import 'package:hoplixi/main_store/dao/store_meta_dao.dart';
import 'package:hoplixi/main_store/dao/store_settings_dao.dart';
import 'package:hoplixi/main_store/dao/vault_item_dao.dart';
import 'package:hoplixi/main_store/dao/wifi_dao.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/index.dart';
import 'package:hoplixi/main_store/triggers/index.dart';
import 'package:uuid/uuid.dart';

import './dao/filters_dao/filters_dao.dart';

part 'main_store.g.dart';

@DriftDatabase(
  tables: [
    StoreMetaTable,
    StoreSettings,
    // --- Базовая таблица ---
    VaultItems,
    // --- Type-specific таблицы ---
    PasswordItems,
    ApiKeyItems,
    SshKeyItems,
    CertificateItems,
    ContactItems,
    CryptoWalletItems,
    WifiItems,
    IdentityItems,
    LicenseKeyItems,
    RecoveryCodesItems,
    OtpItems,
    NoteItems,
    NoteLinks,
    BankCardItems,
    FileItems,
    FileMetadata,
    DocumentItems,
    DocumentPages,
    // --- Теги (единая таблица) ---
    ItemTags,
    // --- Вспомогательные ---
    Categories,
    Tags,
    Icons,
    // --- История (Table-Per-Type) ---
    VaultItemHistory,
    PasswordHistory,
    ApiKeyHistory,
    SshKeyHistory,
    CertificateHistory,
    ContactHistory,
    CryptoWalletHistory,
    WifiHistory,
    IdentityHistory,
    LicenseKeyHistory,
    RecoveryCodesHistory,
    OtpHistory,
    NoteHistory,
    BankCardHistory,
    FileHistory,
    DocumentHistory,
  ],
  daos: [
    StoreMetaDao,
    StoreSettingsDao,
    VaultItemDao,
    PasswordDao,
    PasswordHistoryDao,
    ApiKeyDao,
    ApiKeyHistoryDao,
    SshKeyDao,
    SshKeyHistoryDao,
    CertificateDao,
    ContactDao,
    CertificateHistoryDao,
    ContactHistoryDao,
    CryptoWalletDao,
    CryptoWalletHistoryDao,
    WifiDao,
    WifiHistoryDao,
    IdentityDao,
    IdentityHistoryDao,
    LicenseKeyDao,
    LicenseKeyHistoryDao,
    RecoveryCodesDao,
    RecoveryCodesHistoryDao,
    OtpDao,
    OtpHistoryDao,
    NoteDao,
    NoteHistoryDao,
    NoteLinkDao,
    BankCardDao,
    BankCardHistoryDao,
    FileDao,
    FileHistoryDao,
    DocumentDao,
    DocumentHistoryDao,
    CategoryDao,
    IconDao,
    BankCardFilterDao,
    FileFilterDao,
    NoteFilterDao,
    OtpFilterDao,
    PasswordFilterDao,
    ApiKeyFilterDao,
    SshKeyFilterDao,
    CertificateFilterDao,
    ContactFilterDao,
    CryptoWalletFilterDao,
    WifiFilterDao,
    IdentityFilterDao,
    LicenseKeyFilterDao,
    RecoveryCodesFilterDao,
  ],
)
class MainStore extends _$MainStore {
  static const String _logTag = 'MainStore';

  MainStore(super.e);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Установка индексов для оптимизации запросов
        await _installIndexes();

        // Установка триггеров для записи истории изменений
        await _installHistoryTriggers();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        logInfo(
          'Migrating database from version $from to $to',
          tag: '${_logTag}Migration',
        );

        logWarning(
          'Development migration strategy: full schema recreation',
          tag: '${_logTag}Migration',
        );

        await customStatement('PRAGMA foreign_keys = OFF');

        final tableRows = await customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        ).get();

        for (final row in tableRows) {
          final name = row.read<String>('name');
          if (name == null || name.isEmpty) continue;
          final escapedName = name.replaceAll('"', '""');
          await customStatement('DROP TABLE IF EXISTS "$escapedName"');
        }

        await customStatement('PRAGMA foreign_keys = ON');

        await m.createAll();
        await _installIndexes();
        await _installHistoryTriggers();

        logInfo('Migration completed', tag: '${_logTag}Migration');
      },
    );
  }

  @override
  int get schemaVersion => MainConstants.databaseSchemaVersion;

  /// Поток для отслеживания изменений в данных.
  ///
  /// Эмитирует событие каждый раз при изменении данных
  /// в любой из основных таблиц.
  Stream<void> watchDataChanged() {
    return customSelect(
      'SELECT 1',
      readsFrom: {
        vaultItems,
        passwordItems,
        apiKeyItems,
        sshKeyItems,
        certificateItems,
        contactItems,
        cryptoWalletItems,
        wifiItems,
        identityItems,
        licenseKeyItems,
        recoveryCodesItems,
        otpItems,
        noteItems,
        noteLinks,
        bankCardItems,
        fileItems,
        documentItems,
        documentPages,
        itemTags,
        categories,
        tags,
        icons,
        vaultItemHistory,
      },
    ).watch().map((_) {});
  }

  /// Установка триггеров для автоматической записи истории
  /// изменений и управления временными метками.
  Future<void> _installHistoryTriggers() async {
    logInfo('Installing triggers...', tag: _logTag);

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
        ...otpsHistoryDropTriggers,
        ...notesHistoryDropTriggers,
        ...filesHistoryDropTriggers,
        ...bankCardsHistoryDropTriggers,
        ...documentsDropTriggers,
      ]) {
        await customStatement(drop);
      }

      // Удаляем старые триггеры временных меток (если есть)
      for (final drop in allTimestampDropTriggers) {
        await customStatement(drop);
      }

      // Удаляем старые триггеры обновления store_meta (если есть)
      for (final drop in allMetaTouchDropTriggers) {
        await customStatement(drop);
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
        ...otpsHistoryCreateTriggers,
        ...notesHistoryCreateTriggers,
        ...filesHistoryCreateTriggers,
        ...bankCardsHistoryCreateTriggers,
        ...documentsHistoryCreateTriggers,
        ...documentsTriggers,
      ]) {
        await customStatement(trigger);
      }

      // Создаём триггеры для автоматической установки created_at
      for (final trigger in allInsertTimestampTriggers) {
        await customStatement(trigger);
      }

      // Создаём триггеры для автоматического обновления modified_at
      for (final trigger in allModifiedAtTriggers) {
        await customStatement(trigger);
      }

      // Создаём триггеры для обновления store_meta
      for (final trigger in allMetaTouchCreateTriggers) {
        await customStatement(trigger);
      }

      logInfo('All triggers installed successfully', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to install triggers',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Создание индексов для оптимизации запросов.
  ///
  /// Вызывается один раз при [onCreate] после [createAll].
  Future<void> _installIndexes() async {
    logInfo('Installing indexes...', tag: _logTag);

    try {
      const indexes = [
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

        // --- note_links ---
        // Входящие ссылки на заметку. Исходящие покрыты UNIQUE (source_note_id, target_note_id).
        'CREATE INDEX IF NOT EXISTS idx_note_links_target '
            'ON note_links (target_note_id)',

        // --- document_pages ---
        // WHERE document_id = ? AND is_primary = 1 (получение обложки).
        // UNIQUE (document_id, page_number) не покрывает is_primary.
        'CREATE INDEX IF NOT EXISTS idx_doc_pages_primary '
            'ON document_pages (document_id, is_primary)',

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

      for (final sql in indexes) {
        await customStatement(sql);
      }

      logInfo('All indexes installed successfully', tag: _logTag);
    } catch (e, stackTrace) {
      logError(
        'Failed to install indexes',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }
}
