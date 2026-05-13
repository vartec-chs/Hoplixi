import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

import '../vault_items/vault_items.dart';

@DataClassName('IdentityItemsData')
class IdentityItems extends Table {
  @ReferenceName('identityItem')
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Имя.
  TextColumn get firstName => text().nullable()();

  /// Отчество / второе имя.
  TextColumn get middleName => text().nullable()();

  /// Фамилия.
  TextColumn get lastName => text().nullable()();

  /// Отображаемое имя.
  TextColumn get displayName => text().nullable()();

  /// Имя пользователя.
  TextColumn get username => text().nullable()();

  /// Электронная почта.
  TextColumn get email => text().nullable()();

  /// Телефон.
  TextColumn get phone => text().nullable()();

  /// Адрес.
  TextColumn get address => text().nullable()();

  /// День рождения.
  DateTimeColumn get birthday => dateTime().nullable()();

  /// Компания.
  TextColumn get company => text().nullable()();

  /// Должность.
  TextColumn get jobTitle => text().nullable()();

  /// Веб-сайт.
  TextColumn get website => text().nullable()();

  /// ИНН / Налоговый номер.
  TextColumn get taxId => text().nullable()();

  /// Национальный ID / СНИЛС.
  TextColumn get nationalId => text().nullable()();

  /// Номер паспорта.
  TextColumn get passportNumber => text().nullable()();

  /// Номер водительского удостоверения.
  TextColumn get driverLicenseNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'identity_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${IdentityItemConstraint.itemIdNotBlank.constraintName}
    CHECK (length(trim(item_id)) > 0)
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.firstNameNoOuterWhitespace.constraintName}
    CHECK (
      first_name IS NULL
      OR first_name = trim(first_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.middleNameNoOuterWhitespace.constraintName}
    CHECK (
      middle_name IS NULL
      OR middle_name = trim(middle_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.lastNameNoOuterWhitespace.constraintName}
    CHECK (
      last_name IS NULL
      OR last_name = trim(last_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.displayNameNoOuterWhitespace.constraintName}
    CHECK (
      display_name IS NULL
      OR display_name = trim(display_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.usernameNoOuterWhitespace.constraintName}
    CHECK (
      username IS NULL
      OR username = trim(username)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.phoneNoOuterWhitespace.constraintName}
    CHECK (
      phone IS NULL
      OR phone = trim(phone)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.companyNoOuterWhitespace.constraintName}
    CHECK (
      company IS NULL
      OR company = trim(company)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.jobTitleNoOuterWhitespace.constraintName}
    CHECK (
      job_title IS NULL
      OR job_title = trim(job_title)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.websiteNoOuterWhitespace.constraintName}
    CHECK (
      website IS NULL
      OR website = trim(website)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.taxIdNoOuterWhitespace.constraintName}
    CHECK (
      tax_id IS NULL
      OR tax_id = trim(tax_id)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.nationalIdNoOuterWhitespace.constraintName}
    CHECK (
      national_id IS NULL
      OR national_id = trim(national_id)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.passportNumberNoOuterWhitespace.constraintName}
    CHECK (
      passport_number IS NULL
      OR passport_number = trim(passport_number)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.driverLicenseNumberNoOuterWhitespace.constraintName}
    CHECK (
      driver_license_number IS NULL
      OR driver_license_number = trim(driver_license_number)
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.atLeastOneIdentifyingField.constraintName}
    CHECK (
      first_name IS NOT NULL OR
      middle_name IS NOT NULL OR
      last_name IS NOT NULL OR
      display_name IS NOT NULL OR
      username IS NOT NULL OR
      email IS NOT NULL OR
      phone IS NOT NULL OR
      company IS NOT NULL
    )
    ''',
  ];
}

@JsonEnum(fieldRename: FieldRename.snake)
@JsonEnum(fieldRename: FieldRename.snake)
enum IdentityItemConstraint {
  itemIdNotBlank('chk_identity_items_item_id_not_blank'),

  firstNameNoOuterWhitespace(
    'chk_identity_items_first_name_no_outer_whitespace',
  ),

  middleNameNoOuterWhitespace(
    'chk_identity_items_middle_name_no_outer_whitespace',
  ),

  lastNameNoOuterWhitespace('chk_identity_items_last_name_no_outer_whitespace'),

  displayNameNoOuterWhitespace(
    'chk_identity_items_display_name_no_outer_whitespace',
  ),

  usernameNoOuterWhitespace('chk_identity_items_username_no_outer_whitespace'),

  emailNoOuterWhitespace('chk_identity_items_email_no_outer_whitespace'),

  phoneNoOuterWhitespace('chk_identity_items_phone_no_outer_whitespace'),

  companyNoOuterWhitespace('chk_identity_items_company_no_outer_whitespace'),

  jobTitleNoOuterWhitespace('chk_identity_items_job_title_no_outer_whitespace'),

  websiteNoOuterWhitespace('chk_identity_items_website_no_outer_whitespace'),

  taxIdNoOuterWhitespace('chk_identity_items_tax_id_no_outer_whitespace'),

  nationalIdNoOuterWhitespace(
    'chk_identity_items_national_id_no_outer_whitespace',
  ),

  passportNumberNoOuterWhitespace(
    'chk_identity_items_passport_number_no_outer_whitespace',
  ),

  driverLicenseNumberNoOuterWhitespace(
    'chk_identity_items_driver_license_number_no_outer_whitespace',
  ),

  atLeastOneIdentifyingField(
    'chk_identity_items_at_least_one_identifying_field',
  );

  const IdentityItemConstraint(this.constraintName);

  final String constraintName;
}

@JsonEnum(fieldRename: FieldRename.snake)
@JsonEnum(fieldRename: FieldRename.snake)
enum IdentityItemIndex {
  username('idx_identity_items_username'),
  email('idx_identity_items_email'),
  phone('idx_identity_items_phone'),
  company('idx_identity_items_company'),
  birthday('idx_identity_items_birthday');

  const IdentityItemIndex(this.indexName);

  final String indexName;
}

final List<String> identityItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.username.indexName} ON identity_items(username) WHERE username IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.email.indexName} ON identity_items(email) WHERE email IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.phone.indexName} ON identity_items(phone) WHERE phone IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.company.indexName} ON identity_items(company) WHERE company IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.birthday.indexName} ON identity_items(birthday) WHERE birthday IS NOT NULL;',
];

@JsonEnum(fieldRename: FieldRename.snake)
@JsonEnum(fieldRename: FieldRename.snake)
enum IdentityItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_identity_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_identity_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_identity_items_prevent_item_id_update');

  const IdentityItemTrigger(this.triggerName);

  final String triggerName;
}

enum IdentityItemRaise {
  invalidVaultItemType(
    'identity_items.item_id must reference vault_items.id with type = identity',
  ),

  itemIdImmutable('identity_items.item_id is immutable');

  const IdentityItemRaise(this.message);

  final String message;
}

final List<String> identityItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${IdentityItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON identity_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'identity'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${IdentityItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${IdentityItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON identity_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'identity'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${IdentityItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${IdentityItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON identity_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${IdentityItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
