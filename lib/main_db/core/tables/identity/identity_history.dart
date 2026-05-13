import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

import '../vault_items/vault_snapshots_history.dart';

/// History-таблица для специфичных полей identity.
///
/// Данные вставляются только триггерами.
@DataClassName('IdentityHistoryData')
class IdentityHistory extends Table {
  @ReferenceName('identityHistory')
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Имя snapshot.
  TextColumn get firstName => text().nullable()();

  /// Отчество / второе имя snapshot.
  TextColumn get middleName => text().nullable()();

  /// Фамилия snapshot.
  TextColumn get lastName => text().nullable()();

  /// Отображаемое имя snapshot.
  TextColumn get displayName => text().nullable()();

  /// Имя пользователя snapshot.
  TextColumn get username => text().nullable()();

  /// Электронная почта snapshot.
  TextColumn get email => text().nullable()();

  /// Телефон snapshot.
  TextColumn get phone => text().nullable()();

  /// Адрес snapshot.
  TextColumn get address => text().nullable()();

  /// День рождения snapshot.
  DateTimeColumn get birthday => dateTime().nullable()();

  /// Компания snapshot.
  TextColumn get company => text().nullable()();

  /// Должность snapshot.
  TextColumn get jobTitle => text().nullable()();

  /// Веб-сайт snapshot.
  TextColumn get website => text().nullable()();

  /// ИНН / Налоговый номер snapshot.
  TextColumn get taxId => text().nullable()();

  /// Национальный ID / СНИЛС snapshot.
  TextColumn get nationalId => text().nullable()();

  /// Номер паспорта snapshot.
  TextColumn get passportNumber => text().nullable()();

  /// Номер водительского удостоверения snapshot.
  TextColumn get driverLicenseNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'identity_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${IdentityHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (length(trim(history_id)) > 0)
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.firstNameNoOuterWhitespace.constraintName}
    CHECK (
      first_name IS NULL
      OR first_name = trim(first_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.middleNameNoOuterWhitespace.constraintName}
    CHECK (
      middle_name IS NULL
      OR middle_name = trim(middle_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.lastNameNoOuterWhitespace.constraintName}
    CHECK (
      last_name IS NULL
      OR last_name = trim(last_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.displayNameNoOuterWhitespace.constraintName}
    CHECK (
      display_name IS NULL
      OR display_name = trim(display_name)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.usernameNoOuterWhitespace.constraintName}
    CHECK (
      username IS NULL
      OR username = trim(username)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.phoneNoOuterWhitespace.constraintName}
    CHECK (
      phone IS NULL
      OR phone = trim(phone)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.companyNoOuterWhitespace.constraintName}
    CHECK (
      company IS NULL
      OR company = trim(company)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.jobTitleNoOuterWhitespace.constraintName}
    CHECK (
      job_title IS NULL
      OR job_title = trim(job_title)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.websiteNoOuterWhitespace.constraintName}
    CHECK (
      website IS NULL
      OR website = trim(website)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.taxIdNoOuterWhitespace.constraintName}
    CHECK (
      tax_id IS NULL
      OR tax_id = trim(tax_id)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.nationalIdNoOuterWhitespace.constraintName}
    CHECK (
      national_id IS NULL
      OR national_id = trim(national_id)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.passportNumberNoOuterWhitespace.constraintName}
    CHECK (
      passport_number IS NULL
      OR passport_number = trim(passport_number)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.driverLicenseNumberNoOuterWhitespace.constraintName}
    CHECK (
      driver_license_number IS NULL
      OR driver_license_number = trim(driver_license_number)
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.atLeastOneIdentifyingField.constraintName}
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
enum IdentityHistoryConstraint {
  historyIdNotBlank('chk_identity_history_history_id_not_blank'),

  firstNameNoOuterWhitespace(
    'chk_identity_history_first_name_no_outer_whitespace',
  ),

  middleNameNoOuterWhitespace(
    'chk_identity_history_middle_name_no_outer_whitespace',
  ),

  lastNameNoOuterWhitespace(
    'chk_identity_history_last_name_no_outer_whitespace',
  ),

  displayNameNoOuterWhitespace(
    'chk_identity_history_display_name_no_outer_whitespace',
  ),

  usernameNoOuterWhitespace(
    'chk_identity_history_username_no_outer_whitespace',
  ),

  emailNoOuterWhitespace('chk_identity_history_email_no_outer_whitespace'),

  phoneNoOuterWhitespace('chk_identity_history_phone_no_outer_whitespace'),

  companyNoOuterWhitespace('chk_identity_history_company_no_outer_whitespace'),

  jobTitleNoOuterWhitespace(
    'chk_identity_history_job_title_no_outer_whitespace',
  ),

  websiteNoOuterWhitespace('chk_identity_history_website_no_outer_whitespace'),

  taxIdNoOuterWhitespace('chk_identity_history_tax_id_no_outer_whitespace'),

  nationalIdNoOuterWhitespace(
    'chk_identity_history_national_id_no_outer_whitespace',
  ),

  passportNumberNoOuterWhitespace(
    'chk_identity_history_passport_number_no_outer_whitespace',
  ),

  driverLicenseNumberNoOuterWhitespace(
    'chk_identity_history_driver_license_number_no_outer_whitespace',
  ),

  atLeastOneIdentifyingField(
    'chk_identity_history_at_least_one_identifying_field',
  );

  const IdentityHistoryConstraint(this.constraintName);

  final String constraintName;
}

@JsonEnum(fieldRename: FieldRename.snake)
enum IdentityHistoryIndex {
  username('idx_identity_history_username'),
  email('idx_identity_history_email'),
  phone('idx_identity_history_phone'),
  company('idx_identity_history_company'),
  birthday('idx_identity_history_birthday');

  const IdentityHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> identityHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.username.indexName} ON identity_history(username) WHERE username IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.email.indexName} ON identity_history(email) WHERE email IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.phone.indexName} ON identity_history(phone) WHERE phone IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.company.indexName} ON identity_history(company) WHERE company IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.birthday.indexName} ON identity_history(birthday) WHERE birthday IS NOT NULL;',
];

@JsonEnum(fieldRename: FieldRename.snake)
enum IdentityHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_identity_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_identity_history_prevent_update');

  const IdentityHistoryTrigger(this.triggerName);

  final String triggerName;
}

@JsonEnum(fieldRename: FieldRename.snake)
enum IdentityHistoryRaise {
  invalidSnapshotType(
    'identity_history.history_id must reference vault_snapshots_history.id with type = identity',
  ),

  historyIsImmutable('identity_history rows are immutable');

  const IdentityHistoryRaise(this.message);

  final String message;
}

final List<String> identityHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${IdentityHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON identity_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'identity'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${IdentityHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${IdentityHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON identity_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${IdentityHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
