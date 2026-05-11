import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';

/// History-таблица для специфичных полей контакта.
///
/// Данные вставляются только триггерами.
@DataClassName('ContactHistoryData')
class ContactHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

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

  /// Дополнительные данные в JSON-формате snapshot.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'contact_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ContactHistoryConstraint.phoneNotBlank.constraintName}
    CHECK (
      phone IS NULL
      OR length(trim(phone)) > 0
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
    CONSTRAINT ${ContactHistoryConstraint.companyNotBlank.constraintName}
    CHECK (
      company IS NULL
      OR length(trim(company)) > 0
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
  ];
}

enum ContactHistoryConstraint {
  phoneNotBlank('chk_contact_history_phone_not_blank'),

  emailNotBlank('chk_contact_history_email_not_blank'),

  companyNotBlank('chk_contact_history_company_not_blank'),

  jobTitleNotBlank('chk_contact_history_job_title_not_blank'),

  addressNotBlank('chk_contact_history_address_not_blank'),

  websiteNotBlank('chk_contact_history_website_not_blank');

  const ContactHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum ContactHistoryIndex {
  phone('idx_contact_history_phone'),
  email('idx_contact_history_email'),
  company('idx_contact_history_company'),
  isEmergencyContact('idx_contact_history_is_emergency_contact'),
  birthday('idx_contact_history_birthday');

  const ContactHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> contactHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.phone.indexName} ON contact_history(phone);',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.email.indexName} ON contact_history(email);',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.company.indexName} ON contact_history(company);',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.isEmergencyContact.indexName} ON contact_history(is_emergency_contact);',
  'CREATE INDEX IF NOT EXISTS ${ContactHistoryIndex.birthday.indexName} ON contact_history(birthday);',
];
