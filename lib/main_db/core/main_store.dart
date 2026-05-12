import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/old/daos/daos.dart';
import 'package:hoplixi/main_db/core/main_store_indexes_installer.dart';
import 'package:hoplixi/main_db/core/migrations/index.dart';
import 'package:hoplixi/main_db/core/old/models/enums/index.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';
import 'package:uuid/uuid.dart';

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
    FileItems,
    FileMetadata,
    FileMetadataHistory,
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
    Icons,
    IconRefs,
    ItemCategoryHistory,
    VaultItemTagHistory,
    ItemLinkHistory,
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
    LoyaltyCardItems,
    LoyaltyCardHistory,
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
    LoyaltyCardDao,
    LoyaltyCardHistoryDao,
    LoyaltyCardFilterDao,
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
    CustomFieldDao,
    CustomFieldHistoryDao,
    DocumentFilterDao,
    TagDao,
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

        var currentVersion = from;

        final migrationRuntime = MainStoreMigrationRuntime(
          customStatement: (sql) => customStatement(sql),
          reinstallHistoryTriggers: _installHistoryTriggers,
          categoriesTable: categories,
          vaultItemsTable: vaultItems,
          vaultItemHistoryTable: vaultItemHistory,
        );

        currentVersion = await runMainStoreKnownMigrations(
          migrator: m,
          from: currentVersion,
          to: to,
          runtime: migrationRuntime,
          logTag: '${_logTag}Migration',
        );

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
          await _installHistoryTriggers();
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
        storeSettings,
        vaultItems,
        passwordItems,
        passwordHistory,
        apiKeyItems,
        apiKeyHistory,
        sshKeyItems,
        sshKeyHistory,
        certificateItems,
        certificateHistory,
        contactItems,
        contactHistory,
        cryptoWalletItems,
        cryptoWalletHistory,
        wifiItems,
        wifiHistory,
        identityItems,
        identityHistory,
        licenseKeyItems,
        licenseKeyHistory,
        recoveryCodesItems,
        recoveryCodesHistory,
        recoveryCodes,
        loyaltyCardItems,
        loyaltyCardHistory,
        otpItems,
        otpHistory,
        noteItems,
        itemLinks,
        itemLinkHistory,
        noteHistory,
        bankCardItems,
        bankCardHistory,
        fileItems,
        fileHistory,
        fileMetadataHistory,
        documentItems,
        documentPages,
        documentVersions,
        documentVersionPages,
        itemTags,
        itemCategoryHistory,
        vaultItemTagHistory,
        vaultItemCustomFields,
        vaultItemCustomFieldsHistory,
        categories,
        tags,
        icons,
        iconRefs,
        vaultItemHistory,
        fileMetadata,
      },
    ).watch().map((_) {});
  }

  /// Установка триггеров для автоматической записи истории
  /// изменений и управления временными метками.
  // Future<void> _installHistoryTriggers() {
  //   return installMainStoreHistoryTriggers(
  //     executeStatement: customStatement,
  //     logTag: _logTag,
  //   );
  // }

  /// Создание индексов для оптимизации запросов.
  ///
  /// Вызывается один раз при [onCreate] после [createAll].
  // Future<void> _installIndexes() {
  //   return installMainStoreIndexes(
  //     executeStatement: customStatement,
  //     logTag: _logTag,
  //   );
  // }
}
