import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum IdentityDocumentType {
  passport,
  idCard,
  driverLicense,
  residencePermit,
  birthCertificate,
  taxId,
  socialSecurity,
  insurance,
  studentId,
  employeeId,
  other,
}

@DataClassName('IdentityItemsData')
class IdentityItems extends Table {
  @ReferenceName('identityItem')
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Тип документа: паспорт, ID-карта, водительские права и т.д.
  TextColumn get idType => textEnum<IdentityDocumentType>()();

  /// Дополнительный тип документа, если idType = other.
  TextColumn get idTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Номер документа.
  ///
  /// Секретное/чувствительное значение. Не ограничиваем длину слишком жёстко.
  TextColumn get idNumber => text()();

  /// Полное имя владельца документа.
  TextColumn get fullName => text().withLength(min: 1, max: 255).nullable()();

  /// Дата рождения.
  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  /// Место рождения.
  TextColumn get placeOfBirth =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Гражданство/национальность.
  TextColumn get nationality =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Орган, выдавший документ.
  TextColumn get issuingAuthority =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Дата выдачи.
  DateTimeColumn get issueDate => dateTime().nullable()();

  /// Дата окончания действия.
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// MRZ строка/блок.
  ///
  /// Чувствительное значение, поэтому без жёсткого лимита.
  TextColumn get mrz => text().nullable()();

  /// Ссылка на скан-документ в хранилище.
  ///
  /// Логически должен ссылаться на vault item типа document.
  /// Это лучше проверять на уровне сервиса/репозитория или trigger'ом.
  @ReferenceName('identityItemScanAttachment')
  TextColumn get scanAttachmentId => text()
      .references(VaultItems, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// Ссылка на фото-файл в хранилище.
  ///
  /// Логически должен ссылаться на vault item типа file.
  @ReferenceName('identityItemPhotoAttachment')
  TextColumn get photoAttachmentId => text()
      .references(VaultItems, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// Проверен ли документ пользователем/системой.
  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Например: страна выдачи, серия документа, пол, address,
  /// document category, OCR confidence, extra MRZ parsed fields.
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'identity_items';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${IdentityItemConstraint.idTypeOtherRequired.constraintName}
    CHECK (
      id_type != 'other'
      OR (
        id_type_other IS NOT NULL
        AND length(trim(id_type_other)) > 0
      )
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.idTypeOtherMustBeNull.constraintName}
    CHECK (
      id_type = 'other'
      OR id_type_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.idNumberNotBlank.constraintName}
    CHECK (
      length(trim(id_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.fullNameNotBlank.constraintName}
    CHECK (
      full_name IS NULL
      OR length(trim(full_name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.placeOfBirthNotBlank.constraintName}
    CHECK (
      place_of_birth IS NULL
      OR length(trim(place_of_birth)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.nationalityNotBlank.constraintName}
    CHECK (
      nationality IS NULL
      OR length(trim(nationality)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.issuingAuthorityNotBlank.constraintName}
    CHECK (
      issuing_authority IS NULL
      OR length(trim(issuing_authority)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.mrzNotBlank.constraintName}
    CHECK (
      mrz IS NULL
      OR length(trim(mrz)) > 0
    )
    ''',

    '''
    CONSTRAINT ${IdentityItemConstraint.issueExpiryRange.constraintName}
    CHECK (
      issue_date IS NULL
      OR expiry_date IS NULL
      OR issue_date <= expiry_date
    )
    ''',
  ];
}

enum IdentityItemConstraint {
  idTypeOtherRequired('chk_identity_items_id_type_other_required'),

  idTypeOtherMustBeNull('chk_identity_items_id_type_other_must_be_null'),

  idNumberNotBlank('chk_identity_items_id_number_not_blank'),

  fullNameNotBlank('chk_identity_items_full_name_not_blank'),

  placeOfBirthNotBlank('chk_identity_items_place_of_birth_not_blank'),

  nationalityNotBlank('chk_identity_items_nationality_not_blank'),

  issuingAuthorityNotBlank('chk_identity_items_issuing_authority_not_blank'),

  mrzNotBlank('chk_identity_items_mrz_not_blank'),

  issueExpiryRange('chk_identity_items_issue_expiry_range');

  const IdentityItemConstraint(this.constraintName);

  final String constraintName;
}

enum IdentityItemIndex {
  idType('idx_identity_items_id_type'),
  fullName('idx_identity_items_full_name'),
  nationality('idx_identity_items_nationality'),
  expiryDate('idx_identity_items_expiry_date'),
  verified('idx_identity_items_verified'),
  scanAttachmentId('idx_identity_items_scan_attachment_id'),
  photoAttachmentId('idx_identity_items_photo_attachment_id');

  const IdentityItemIndex(this.indexName);

  final String indexName;
}

final List<String> identityItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.idType.indexName} ON identity_items(id_type);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.fullName.indexName} ON identity_items(full_name);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.nationality.indexName} ON identity_items(nationality);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.expiryDate.indexName} ON identity_items(expiry_date);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.verified.indexName} ON identity_items(verified);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.scanAttachmentId.indexName} ON identity_items(scan_attachment_id);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.photoAttachmentId.indexName} ON identity_items(photo_attachment_id);',
];
