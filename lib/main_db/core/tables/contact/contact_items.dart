import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

@DataClassName('ContactItemsData')
class ContactItems extends Table {
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Основной телефон.
  TextColumn get phone => text().withLength(min: 1, max: 64).nullable()();

  /// Основной email.
  TextColumn get email => text().withLength(min: 1, max: 320).nullable()();

  /// Компания/организация.
  TextColumn get company => text().withLength(min: 1, max: 255).nullable()();

  /// Должность.
  TextColumn get jobTitle => text().withLength(min: 1, max: 255).nullable()();

  /// Адрес.
  ///
  /// Не делим на страну/город/улицу, чтобы не усложнять локальный vault.
  TextColumn get address => text().nullable()();

  /// Сайт контакта.
  TextColumn get website => text().withLength(min: 1, max: 2048).nullable()();

  /// День рождения.
  DateTimeColumn get birthday => dateTime().nullable()();

  /// Экстренный контакт.
  BoolColumn get isEmergencyContact =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'contact_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ContactItemConstraint.phoneNotBlank.constraintName}
    CHECK (
      phone IS NULL
      OR length(trim(phone)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactItemConstraint.emailNotBlank.constraintName}
    CHECK (
      email IS NULL
      OR length(trim(email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactItemConstraint.companyNotBlank.constraintName}
    CHECK (
      company IS NULL
      OR length(trim(company)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactItemConstraint.jobTitleNotBlank.constraintName}
    CHECK (
      job_title IS NULL
      OR length(trim(job_title)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactItemConstraint.addressNotBlank.constraintName}
    CHECK (
      address IS NULL
      OR length(trim(address)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactItemConstraint.websiteNotBlank.constraintName}
    CHECK (
      website IS NULL
      OR length(trim(website)) > 0
    )
    ''',
  ];
}

enum ContactItemConstraint {
  phoneNotBlank('chk_contact_items_phone_not_blank'),

  emailNotBlank('chk_contact_items_email_not_blank'),

  companyNotBlank('chk_contact_items_company_not_blank'),

  jobTitleNotBlank('chk_contact_items_job_title_not_blank'),

  addressNotBlank('chk_contact_items_address_not_blank'),

  websiteNotBlank('chk_contact_items_website_not_blank');

  const ContactItemConstraint(this.constraintName);

  final String constraintName;
}

enum ContactItemIndex {
  phone('idx_contact_items_phone'),
  email('idx_contact_items_email'),
  company('idx_contact_items_company'),
  birthday('idx_contact_items_birthday');

  const ContactItemIndex(this.indexName);

  final String indexName;
}

final List<String> contactItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ContactItemIndex.phone.indexName} ON contact_items(phone);',
  'CREATE INDEX IF NOT EXISTS ${ContactItemIndex.email.indexName} ON contact_items(email);',
  'CREATE INDEX IF NOT EXISTS ${ContactItemIndex.company.indexName} ON contact_items(company);',
  'CREATE INDEX IF NOT EXISTS ${ContactItemIndex.birthday.indexName} ON contact_items(birthday);',
];

enum ContactItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_contact_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_contact_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_contact_items_prevent_item_id_update');

  const ContactItemTrigger(this.triggerName);

  final String triggerName;
}

enum ContactItemRaise {
  invalidVaultItemType(
    'contact_items.item_id must reference vault_items.id with type = contact',
  ),

  itemIdImmutable('contact_items.item_id is immutable');

  const ContactItemRaise(this.message);

  final String message;
}

final List<String> contactItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ContactItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON contact_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'contact'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ContactItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${ContactItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON contact_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'contact'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ContactItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${ContactItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON contact_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ContactItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
