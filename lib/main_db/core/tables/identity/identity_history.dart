import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'identity_items.dart';

/// History-таблица для специфичных полей identity-документа.
///
/// Данные вставляются только триггерами.
/// Чувствительные поля могут быть NULL, если включён режим истории
/// без сохранения секретов/персональных данных.
@DataClassName('IdentityHistoryData')
class IdentityHistory extends Table {
  @ReferenceName('identityHistory')
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Тип документа snapshot.
  TextColumn get idType => textEnum<IdentityDocumentType>()();

  /// Дополнительный тип документа, если idType = other.
  TextColumn get idTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер документа snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on history policy.
  TextColumn get idNumber => text().nullable()();

  /// Полное имя владельца документа snapshot.
  TextColumn get fullName => text().withLength(min: 1, max: 255).nullable()();

  /// Дата рождения snapshot.
  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  /// Место рождения snapshot.
  TextColumn get placeOfBirth =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Гражданство/национальность snapshot.
  TextColumn get nationality =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Орган, выдавший документ snapshot.
  TextColumn get issuingAuthority =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дата выдачи snapshot.
  DateTimeColumn get issueDate => dateTime().nullable()();

  /// Дата окончания действия snapshot.
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// MRZ snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get mrz => text().nullable()();

  /// Ссылка на scan/document attachment snapshot.
  ///
  /// Не FK специально: history должна хранить снимок значения,
  /// даже если связанный vault item позже удалён.
  TextColumn get scanAttachmentId => text().nullable()();

  /// Ссылка на photo/file attachment snapshot.
  ///
  /// Не FK специально.
  TextColumn get photoAttachmentId => text().nullable()();

  /// Проверен ли документ snapshot.
  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'identity_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${IdentityHistoryConstraint.idTypeOtherRequired.constraintName}
    CHECK (
      id_type != 'other'
      OR (
        id_type_other IS NOT NULL
        AND length(trim(id_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.idTypeOtherMustBeNull.constraintName}
    CHECK (
      id_type = 'other'
      OR id_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.idNumberNotBlank.constraintName}
    CHECK (
      id_number IS NULL
      OR length(trim(id_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.fullNameNotBlank.constraintName}
    CHECK (
      full_name IS NULL
      OR length(trim(full_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.placeOfBirthNotBlank.constraintName}
    CHECK (
      place_of_birth IS NULL
      OR length(trim(place_of_birth)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.nationalityNotBlank.constraintName}
    CHECK (
      nationality IS NULL
      OR length(trim(nationality)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.issuingAuthorityNotBlank.constraintName}
    CHECK (
      issuing_authority IS NULL
      OR length(trim(issuing_authority)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.mrzNotBlank.constraintName}
    CHECK (
      mrz IS NULL
      OR length(trim(mrz)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityHistoryConstraint.issueExpiryRange.constraintName}
    CHECK (
      issue_date IS NULL
      OR expiry_date IS NULL
      OR issue_date <= expiry_date
    )
    ''',
  ];
}

enum IdentityHistoryConstraint {
  idTypeOtherRequired('chk_identity_history_id_type_other_required'),

  idTypeOtherMustBeNull('chk_identity_history_id_type_other_must_be_null'),

  idNumberNotBlank('chk_identity_history_id_number_not_blank'),

  fullNameNotBlank('chk_identity_history_full_name_not_blank'),

  placeOfBirthNotBlank('chk_identity_history_place_of_birth_not_blank'),

  nationalityNotBlank('chk_identity_history_nationality_not_blank'),

  issuingAuthorityNotBlank('chk_identity_history_issuing_authority_not_blank'),

  mrzNotBlank('chk_identity_history_mrz_not_blank'),

  issueExpiryRange('chk_identity_history_issue_expiry_range');

  const IdentityHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum IdentityHistoryIndex {
  idType('idx_identity_history_id_type'),
  fullName('idx_identity_history_full_name'),
  nationality('idx_identity_history_nationality'),
  expiryDate('idx_identity_history_expiry_date'),
  verified('idx_identity_history_verified'),
  scanAttachmentId('idx_identity_history_scan_attachment_id'),
  photoAttachmentId('idx_identity_history_photo_attachment_id');

  const IdentityHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> identityHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.idType.indexName} ON identity_history(id_type);',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.fullName.indexName} ON identity_history(full_name);',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.nationality.indexName} ON identity_history(nationality);',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.expiryDate.indexName} ON identity_history(expiry_date);',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.verified.indexName} ON identity_history(verified);',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.scanAttachmentId.indexName} ON identity_history(scan_attachment_id);',
  'CREATE INDEX IF NOT EXISTS ${IdentityHistoryIndex.photoAttachmentId.indexName} ON identity_history(photo_attachment_id);',
];
