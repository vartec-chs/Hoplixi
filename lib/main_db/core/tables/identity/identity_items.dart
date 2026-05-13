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

  /// Проверен ли документ пользователем/системой.
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
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
  expiryDate('idx_identity_items_expiry_date');

  const IdentityItemIndex(this.indexName);

  final String indexName;
}

final List<String> identityItemsTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.idType.indexName} ON identity_items(id_type);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.fullName.indexName} ON identity_items(full_name);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.nationality.indexName} ON identity_items(nationality);',
  'CREATE INDEX IF NOT EXISTS ${IdentityItemIndex.expiryDate.indexName} ON identity_items(expiry_date);',
];

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
