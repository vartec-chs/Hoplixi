import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/core/dao/daos.dart';
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
    ApiKeyItemsDao,
    SshKeyItemsDao,
    CertificateItemsDao,
    CryptoWalletItemsDao,
    WifiItemsDao,
    IdentityItemsDao,
    LicenseKeyItemsDao,
    RecoveryCodesItemsDao,
    RecoveryCodesDao,
    RecoveryCodesHistoryDao,
    RecoveryCodeValuesHistoryDao,
    LoyaltyCardItemsDao,
    LoyaltyCardHistoryDao,
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
        // await _installIndexes();

        // Установка триггеров для записи истории изменений
        // await _installHistoryTriggers();
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

        // final migrationRuntime = MainStoreMigrationRuntime(
        //   customStatement: (sql) => customStatement(sql),
        //   reinstallHistoryTriggers: _installHistoryTriggers,
        //   categoriesTable: categories,
        //   vaultItemsTable: vaultItems,
        // );

        // currentVersion = await runMainStoreKnownMigrations(
        //   migrator: m,
        //   from: currentVersion,
        //   to: to,
        //   runtime: migrationRuntime,
        //   logTag: '${_logTag}Migration',
        // );

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
          // await _installIndexes();
          // await _installHistoryTriggers();
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
