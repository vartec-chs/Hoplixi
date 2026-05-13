import 'package:drift/drift.dart';

import '../vault_items/vault_snapshots_history.dart';

/// History-таблица для специфичных полей контакта.
///
/// Данные вставляются только триггерами.
@DataClassName('ContactHistoryData')
class ContactHistory extends Table {
  TextColumn get historyId => text().references(
    VaultSnapshotsHistory,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Основной телефон snapshot.
  TextColumn get phone => text().withLength(min: 1, max: 64).nullable()();

  /// Основной email snapshot.
  TextColumn get email => text().withLength(min: 1, max: 320).nullable()();

  /// Компания/организация snapshot.
  TextColumn get company => text().withLength(min: 1, max: 255).nullable()();

  /// Должность snapshot.
  TextColumn get jobTitle => text().withLength(min: 1, max: 255).nullable()();

  /// Адрес snapshot.
  TextColumn get address => text().nullable()();

  /// Сайт контакта snapshot.
  TextColumn get website => text().withLength(min: 1, max: 2048).nullable()();

  /// День рождения snapshot.
  DateTimeColumn get birthday => dateTime().nullable()();

  /// Экстренный контакт snapshot.
  BoolColumn get isEmergencyContact =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'contact_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ContactHistoryConstraint.historyIdNotBlank.constraintName}
    CHECK (length(trim(history_id)) > 0)
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.phoneNotBlank.constraintName}
    CHECK (
      phone IS NULL
      OR length(trim(phone)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.phoneNoOuterWhitespace.constraintName}
    CHECK (
      phone IS NULL
      OR phone = trim(phone)
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.emailNotBlank.constraintName}
    CHECK (
      email IS NULL
      OR length(trim(email)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.emailNoOuterWhitespace.constraintName}
    CHECK (
      email IS NULL
      OR email = trim(email)
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.companyNotBlank.constraintName}
    CHECK (
      company IS NULL
      OR length(trim(company)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.companyNoOuterWhitespace.constraintName}
    CHECK (
      company IS NULL
      OR company = trim(company)
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.jobTitleNotBlank.constraintName}
    CHECK (
      job_title IS NULL
      OR length(trim(job_title)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.jobTitleNoOuterWhitespace.constraintName}
    CHECK (
      job_title IS NULL
      OR job_title = trim(job_title)
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.addressNotBlank.constraintName}
    CHECK (
      address IS NULL
      OR length(trim(address)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.websiteNotBlank.constraintName}
    CHECK (
      website IS NULL
      OR length(trim(website)) > 0
    )
    ''',

    '''
    CONSTRAINT ${ContactHistoryConstraint.websiteNoOuterWhitespace.constraintName}
    CHECK (
      website IS NULL
      OR website = trim(website)
    )
    ''',
  ];
}

enum ContactHistoryConstraint {
  historyIdNotBlank('chk_contact_history_history_id_not_blank'),

  phoneNotBlank('chk_contact_history_phone_not_blank'),

  phoneNoOuterWhitespace('chk_contact_history_phone_no_outer_whitespace'),

  emailNotBlank('chk_contact_history_email_not_blank'),

  emailNoOuterWhitespace('chk_contact_history_email_no_outer_whitespace'),

  companyNotBlank('chk_contact_history_company_not_blank'),

  companyNoOuterWhitespace('chk_contact_history_company_no_outer_whitespace'),

  jobTitleNotBlank('chk_contact_history_job_title_not_blank'),

  jobTitleNoOuterWhitespace(
    'chk_contact_history_job_title_no_outer_whitespace',
  ),

  addressNotBlank('chk_contact_history_address_not_blank'),

  websiteNotBlank('chk_contact_history_website_not_blank'),

  websiteNoOuterWhitespace('chk_contact_history_website_no_outer_whitespace');

  const ContactHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ContactHistoryIndex {
  phone('idx_contact_history_phone'),
  email('idx_contact_history_email'),
  company('idx_contact_history_company'),
  birthday('idx_contact_history_birthday');

  const ContactHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> contactHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.phone.indexName} ON contact_history(phone) WHERE phone IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.email.indexName} ON contact_history(email) WHERE email IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.company.indexName} ON contact_history(company) WHERE company IS NOT NULL;',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.birthday.indexName} ON contact_history(birthday) WHERE birthday IS NOT NULL;',
];

enum ContactHistoryTrigger {
  validateSnapshotTypeOnInsert(
    'trg_contact_history_validate_snapshot_type_on_insert',
  ),

  preventUpdate('trg_contact_history_prevent_update');

  const ContactHistoryTrigger(this.triggerName);

  final String triggerName;
}

enum ContactHistoryRaise {
  invalidSnapshotType(
    'contact_history.history_id must reference vault_snapshots_history.id with type = contact',
  ),

  historyIsImmutable('contact_history rows are immutable');

  const ContactHistoryRaise(this.message);

  final String message;
}

final List<String> contactHistoryTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ContactHistoryTrigger.validateSnapshotTypeOnInsert.triggerName}
  BEFORE INSERT ON contact_history
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_snapshots_history
    WHERE id = NEW.history_id
      AND type = 'contact'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ContactHistoryRaise.invalidSnapshotType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${ContactHistoryTrigger.preventUpdate.triggerName}
  BEFORE UPDATE ON contact_history
  FOR EACH ROW
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ContactHistoryRaise.historyIsImmutable.message}'
    );
  END;
  ''',
];
