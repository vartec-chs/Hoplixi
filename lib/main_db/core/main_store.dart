import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/main_db/core/daos/daos.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';
import 'package:uuid/uuid.dart';

import 'tables/all_table_indexes.dart';
import 'tables/all_table_triggers.dart';

part 'main_store.g.dart';

@DriftDatabase(
  tables: [
    // --- Мета-таблицы ---
    StoreMetaTable,
    StoreSettings,
    // --- Базовая таблица ---
    VaultItems,
    // --- Type-specific таблицы ---
    PasswordItems,
    ApiKeyItems,
    SshKeyItems,
    LoyaltyCardItems,
    CertificateItems,
    ContactItems,
    CryptoWalletItems,
    WifiItems,
    IdentityItems,
    LicenseKeyItems,
    RecoveryCodesItems,
    RecoveryCodes,
    OtpItems,
    NoteItems,
    ItemLinks,
    BankCardItems,
    // --- Файлы ---
    FileItems,
    FileMetadata,
    FileMetadataHistory,
    FileHistory,
    // --- Документы ---
    DocumentItems,
    DocumentPages,
    DocumentVersions,
    DocumentVersionPages,
    // --- Теги (единая таблица) ---
    ItemTags,
    // --- Кастомные поля ---
    VaultItemCustomFields,
    VaultItemCustomFieldsHistory,
    // --- Вспомогательные ---
    Categories,
    Tags,
    // --- Иконки ---
    CustomIcons,
    IconRefs,
    ItemCategoryHistory,
    // --- История (Event Sourcing) ---
    VaultEventsHistory,
    VaultSnapshotsHistory,
    VaultItemTagHistory,
    ItemLinkHistory,
    // --- История (Table-Per-Type) ---
    ApiKeyHistory,
    BankCardHistory,
    CertificateHistory,
    CryptoWalletHistory,
    ContactHistory,
    IdentityHistory,
    LicenseKeyHistory,
    LoyaltyCardHistory,
    OtpHistory,
    NoteHistory,
    PasswordHistory,
    RecoveryCodesHistory,
    RecoveryCodeValuesHistory,
    SshKeyHistory,
    WifiHistory,
  ],
  daos: [
    CategoriesDao,
    TagsDao,
    ItemTagsDao,
    ItemLinksDao,
    CustomIconsDao,
    IconRefsDao,
    StoreSettingsDao,
    StoreMetaDao,
    ItemCategoryHistoryDao,
    VaultItemTagHistoryDao,
    ItemLinkHistoryDao,
    VaultItemsDao,
    PasswordItemsDao,
    OtpItemsDao,
    NoteItemsDao,
    BankCardItemsDao,
    DocumentItemsDao,
    DocumentPagesDao,
    DocumentVersionsDao,
    DocumentVersionPagesDao,
    FileItemsDao,
    FileMetadataDao,
    FileHistoryDao,
    FileMetadataHistoryDao,
    ContactItemsDao,
    ContactHistoryDao,
    ApiKeyItemsDao,
    ApiKeyHistoryDao,
    SshKeyItemsDao,
    SshKeyHistoryDao,
    CertificateItemsDao,
    CertificateHistoryDao,
    CryptoWalletItemsDao,
    CryptoWalletHistoryDao,
    WifiItemsDao,
    WifiHistoryDao,
    IdentityItemsDao,
    IdentityHistoryDao,
    LicenseKeyItemsDao,
    LicenseKeyHistoryDao,
    OtpHistoryDao,
    PasswordHistoryDao,
    NoteHistoryDao,
    BankCardHistoryDao,
    RecoveryCodesItemsDao,
    RecoveryCodesDao,
    RecoveryCodesHistoryDao,
    RecoveryCodeValuesHistoryDao,
    LoyaltyCardItemsDao,
    LoyaltyCardHistoryDao,
    VaultEventsHistoryDao,
    VaultSnapshotsHistoryDao,
    // Filter DAOs
    ApiKeyFilterDao,
    BankCardFilterDao,
    CertificateFilterDao,
    ContactFilterDao,
    CryptoWalletFilterDao,
    DocumentFilterDao,
    FileFilterDao,
    IdentityFilterDao,
    LicenseKeyFilterDao,
    LoyaltyCardFilterDao,
    NoteFilterDao,
    OtpFilterDao,
    PasswordFilterDao,
    RecoveryCodesFilterDao,
    SshKeyFilterDao,
    WifiFilterDao,
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

        // Установка триггеров для бизнес-логики и истории
        await _installTriggers();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        logInfo(
          'Migrating database from version $from to $to',
          tag: '${_logTag}Migration',
        );

        var currentVersion = from;

        if (currentVersion < to) {
          logWarning(
            'Falling back to development migration strategy for remaining versions',
            tag: '${_logTag}Migration',
          );

          await customStatement('PRAGMA foreign_keys = OFF');

          final tableRows = await customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
          ).get();

          for (final row in tableRows) {
            final name = row.read<String>('name');
            if (name.isEmpty) continue;
            final escapedName = name.replaceAll('"', '""');
            await customStatement('DROP TABLE IF EXISTS "$escapedName"');
          }

          await customStatement('PRAGMA foreign_keys = ON');

          await m.createAll();
          await _installIndexes();
          await _installTriggers();
        }

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
        // storeSettings,
        // vaultItems,
        // passwordItems,
        // passwordHistory,
        // apiKeyItems,
        // apiKeyHistory,
        // sshKeyItems,
        // sshKeyHistory,
        // certificateItems,
        // certificateHistory,
        // contactItems,
        // contactHistory,
        // cryptoWalletItems,
        // cryptoWalletHistory,
        // wifiItems,
        // wifiHistory,
        // identityItems,
        // identityHistory,
        // licenseKeyItems,
        // licenseKeyHistory,
        // recoveryCodesItems,
        // recoveryCodesHistory,
        // recoveryCodes,
        // loyaltyCardItems,
        // loyaltyCardHistory,
        // otpItems,
        // otpHistory,
        // noteItems,
        // itemLinks,
        // itemLinkHistory,
        // noteHistory,
        // bankCardItems,
        // bankCardHistory,
        // fileItems,
        // fileHistory,
        // fileMetadataHistory,
        // documentItems,
        // documentPages,
        // documentVersions,
        // documentVersionPages,
        // itemTags,
        // itemCategoryHistory,
        // vaultItemTagHistory,
        // vaultItemCustomFields,
        // vaultItemCustomFieldsHistory,
        // categories,
        // tags,
        // icons,
        // iconRefs,
        // vaultSnapshotsHistory,
        // vaultEventsHistory,
        // fileMetadata,
      },
    ).watch().map((_) {});
  }

  /// Установка всех SQL триггеров.
  Future<void> _installTriggers() async {
    for (final trigger in allTableTriggers) {
      await customStatement(trigger);
    }
  }

  /// Удаление всех пользовательских триггеров.
  Future<void> _dropTriggers() async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='trigger' AND name NOT LIKE 'sqlite_%'",
    ).get();
    for (final row in rows) {
      final name = row.read<String>('name');
      await customStatement('DROP TRIGGER IF EXISTS "$name"');
    }
  }

  /// Установка всех SQL индексов.
  Future<void> _installIndexes() async {
    for (final index in allTableIndexes) {
      await customStatement(index);
    }
  }

  /// Удаление всех пользовательских индексов.
  Future<void> _dropIndexes() async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%' AND origin = 'u'",
    ).get();
    for (final row in rows) {
      final name = row.read<String>('name');
      await customStatement('DROP INDEX IF EXISTS "$name"');
    }
  }
}
