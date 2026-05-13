import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum CertificateFormat { pem, der, pfx, pkcs12, other }

enum CertificateKeyAlgorithm { rsa, ecdsa, ed25519, dsa, other }

@DataClassName('CertificateItemsData')
class CertificateItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE.
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Формат сертификата: PEM, DER, PFX/PKCS#12 и т.д.
  TextColumn get certificateFormat =>
      textEnum<CertificateFormat>().nullable()();

  /// Дополнительный формат, если certificateFormat = other.
  TextColumn get certificateFormatOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// PEM/текстовое представление сертификата.
  ///
  /// Nullable, потому что сертификат может храниться как бинарный DER/PFX.
  TextColumn get certificatePem => text().nullable()();

  /// DER/PFX/PKCS#12 или другой бинарный контейнер.
  BlobColumn get certificateBlob => blob().nullable()();

  /// Приватный ключ.
  ///
  /// Секретное значение. Может быть NULL, если хранится только сертификат.
  TextColumn get privateKey => text().nullable()();

  /// Пароль от privateKey, если он есть.
  TextColumn get privateKeyPassword => text().nullable()();

  /// Пароль от PFX/PKCS#12.
  TextColumn get passwordForPfx => text().nullable()();

  /// Алгоритм ключа: RSA, ECDSA, Ed25519 и т.д.
  TextColumn get keyAlgorithm =>
      textEnum<CertificateKeyAlgorithm>().nullable()();

  /// Дополнительный алгоритм, если keyAlgorithm = other.
  TextColumn get keyAlgorithmOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Размер ключа, например 2048, 4096.
  IntColumn get keySize => integer().nullable()();

  /// Серийный номер сертификата.
  TextColumn get serialNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Issuer сертификата.
  TextColumn get issuer => text().nullable()();

  /// Subject сертификата.
  TextColumn get subject => text().nullable()();

  /// Дата начала действия сертификата.
  DateTimeColumn get validFrom => dateTime().nullable()();

  /// Дата окончания действия сертификата.
  DateTimeColumn get validTo => dateTime().nullable()();

  /// OCSP URL.
  TextColumn get ocspUrl => text().withLength(min: 1, max: 2048).nullable()();

  /// CRL URL.
  TextColumn get crlUrl => text().withLength(min: 1, max: 2048).nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'certificate_items';

  @override
  List<String> get customConstraints => [
    '''
        CONSTRAINT ${CertificateItemConstraint.itemIdNotBlank.constraintName}
        CHECK (
          length(trim(item_id)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.certificateContentRequired.constraintName}
        CHECK (
          certificate_pem IS NOT NULL
          OR certificate_blob IS NOT NULL
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.certificatePemNotBlank.constraintName}
        CHECK (
          certificate_pem IS NULL
          OR length(trim(certificate_pem)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.certificateBlobNotEmpty.constraintName}
        CHECK (
          certificate_blob IS NULL
          OR length(certificate_blob) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.pemFormatRequiresPem.constraintName}
        CHECK (
          certificate_format != 'pem'
          OR certificate_pem IS NOT NULL
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.binaryFormatRequiresBlob.constraintName}
        CHECK (
          certificate_format NOT IN ('der', 'pfx', 'pkcs12')
          OR certificate_blob IS NOT NULL
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.certificateFormatOtherRequired.constraintName}
        CHECK (
          certificate_format IS NULL
          OR certificate_format != 'other'
          OR (
            certificate_format_other IS NOT NULL
            AND length(trim(certificate_format_other)) > 0
          )
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.certificateFormatOtherMustBeNull.constraintName}
        CHECK (
          certificate_format = 'other'
          OR certificate_format_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.certificateFormatOtherNoOuterWhitespace.constraintName}
        CHECK (
          certificate_format_other IS NULL
          OR certificate_format_other = trim(certificate_format_other)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.privateKeyNotBlank.constraintName}
        CHECK (
          private_key IS NULL
          OR length(trim(private_key)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.privateKeyNoOuterWhitespace.constraintName}
        CHECK (
          private_key IS NULL
          OR private_key = trim(private_key)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.privateKeyPasswordNotBlank.constraintName}
        CHECK (
          private_key_password IS NULL
          OR length(trim(private_key_password)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.privateKeyPasswordNoOuterWhitespace.constraintName}
        CHECK (
          private_key_password IS NULL
          OR private_key_password = trim(private_key_password)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.passwordForPfxNotBlank.constraintName}
        CHECK (
          password_for_pfx IS NULL
          OR length(trim(password_for_pfx)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.passwordForPfxNoOuterWhitespace.constraintName}
        CHECK (
          password_for_pfx IS NULL
          OR password_for_pfx = trim(password_for_pfx)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.passwordForPfxRequiresPfxBlob.constraintName}
        CHECK (
          password_for_pfx IS NULL
          OR (
            certificate_format IN ('pfx', 'pkcs12')
            AND certificate_blob IS NOT NULL
          )
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.keyAlgorithmOtherRequired.constraintName}
        CHECK (
          key_algorithm IS NULL
          OR key_algorithm != 'other'
          OR (
            key_algorithm_other IS NOT NULL
            AND length(trim(key_algorithm_other)) > 0
          )
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.keyAlgorithmOtherMustBeNull.constraintName}
        CHECK (
          key_algorithm = 'other'
          OR key_algorithm_other IS NULL
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.keyAlgorithmOtherNoOuterWhitespace.constraintName}
        CHECK (
          key_algorithm_other IS NULL
          OR key_algorithm_other = trim(key_algorithm_other)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.keySizePositive.constraintName}
        CHECK (
          key_size IS NULL
          OR key_size > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.serialNumberNotBlank.constraintName}
        CHECK (
          serial_number IS NULL
          OR length(trim(serial_number)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.serialNumberNoOuterWhitespace.constraintName}
        CHECK (
          serial_number IS NULL
          OR serial_number = trim(serial_number)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.issuerNotBlank.constraintName}
        CHECK (
          issuer IS NULL
          OR length(trim(issuer)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.issuerNoOuterWhitespace.constraintName}
        CHECK (
          issuer IS NULL
          OR issuer = trim(issuer)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.subjectNotBlank.constraintName}
        CHECK (
          subject IS NULL
          OR length(trim(subject)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.subjectNoOuterWhitespace.constraintName}
        CHECK (
          subject IS NULL
          OR subject = trim(subject)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.validRange.constraintName}
        CHECK (
          valid_from IS NULL
          OR valid_to IS NULL
          OR valid_from <= valid_to
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.ocspUrlNotBlank.constraintName}
        CHECK (
          ocsp_url IS NULL
          OR length(trim(ocsp_url)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.ocspUrlNoOuterWhitespace.constraintName}
        CHECK (
          ocsp_url IS NULL
          OR ocsp_url = trim(ocsp_url)
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.crlUrlNotBlank.constraintName}
        CHECK (
          crl_url IS NULL
          OR length(trim(crl_url)) > 0
        )
        ''',

    '''
        CONSTRAINT ${CertificateItemConstraint.crlUrlNoOuterWhitespace.constraintName}
        CHECK (
          crl_url IS NULL
          OR crl_url = trim(crl_url)
        )
        ''',
  ];
}

enum CertificateItemConstraint {
  itemIdNotBlank('chk_certificate_items_item_id_not_blank'),

  certificateContentRequired('chk_certificate_items_content_required'),

  certificatePemNotBlank('chk_certificate_items_certificate_pem_not_blank'),

  certificateBlobNotEmpty('chk_certificate_items_certificate_blob_not_empty'),

  pemFormatRequiresPem('chk_certificate_items_pem_format_requires_pem'),

  binaryFormatRequiresBlob('chk_certificate_items_binary_format_requires_blob'),

  certificateFormatOtherRequired(
    'chk_certificate_items_certificate_format_other_required',
  ),

  certificateFormatOtherMustBeNull(
    'chk_certificate_items_certificate_format_other_must_be_null',
  ),

  certificateFormatOtherNoOuterWhitespace(
    'chk_certificate_items_certificate_format_other_no_outer_whitespace',
  ),

  privateKeyNotBlank('chk_certificate_items_private_key_not_blank'),

  privateKeyNoOuterWhitespace(
    'chk_certificate_items_private_key_no_outer_whitespace',
  ),

  privateKeyPasswordNotBlank(
    'chk_certificate_items_private_key_password_not_blank',
  ),

  privateKeyPasswordNoOuterWhitespace(
    'chk_certificate_items_private_key_password_no_outer_whitespace',
  ),

  passwordForPfxNotBlank('chk_certificate_items_password_for_pfx_not_blank'),

  passwordForPfxNoOuterWhitespace(
    'chk_certificate_items_password_for_pfx_no_outer_whitespace',
  ),

  passwordForPfxRequiresPfxBlob(
    'chk_certificate_items_password_for_pfx_requires_pfx_blob',
  ),

  keyAlgorithmOtherRequired(
    'chk_certificate_items_key_algorithm_other_required',
  ),

  keyAlgorithmOtherMustBeNull(
    'chk_certificate_items_key_algorithm_other_must_be_null',
  ),

  keyAlgorithmOtherNoOuterWhitespace(
    'chk_certificate_items_key_algorithm_other_no_outer_whitespace',
  ),

  keySizePositive('chk_certificate_items_key_size_positive'),

  serialNumberNotBlank('chk_certificate_items_serial_number_not_blank'),

  serialNumberNoOuterWhitespace(
    'chk_certificate_items_serial_number_no_outer_whitespace',
  ),

  issuerNotBlank('chk_certificate_items_issuer_not_blank'),

  issuerNoOuterWhitespace('chk_certificate_items_issuer_no_outer_whitespace'),

  subjectNotBlank('chk_certificate_items_subject_not_blank'),

  subjectNoOuterWhitespace('chk_certificate_items_subject_no_outer_whitespace'),

  validRange('chk_certificate_items_valid_range'),

  ocspUrlNotBlank('chk_certificate_items_ocsp_url_not_blank'),

  ocspUrlNoOuterWhitespace(
    'chk_certificate_items_ocsp_url_no_outer_whitespace',
  ),

  crlUrlNotBlank('chk_certificate_items_crl_url_not_blank'),

  crlUrlNoOuterWhitespace('chk_certificate_items_crl_url_no_outer_whitespace');

  const CertificateItemConstraint(this.constraintName);

  final String constraintName;
}

enum CertificateItemIndex {
  certificateFormat('idx_certificate_items_certificate_format'),

  keyAlgorithm('idx_certificate_items_key_algorithm'),

  validFrom('idx_certificate_items_valid_from'),

  validTo('idx_certificate_items_valid_to'),

  issuer('idx_certificate_items_issuer'),

  subject('idx_certificate_items_subject');

  const CertificateItemIndex(this.indexName);

  final String indexName;
}

final List<String> certificateItemsTableIndexes = [
  '''
  CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.certificateFormat.indexName}
  ON certificate_items(certificate_format)
  WHERE certificate_format IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.keyAlgorithm.indexName}
  ON certificate_items(key_algorithm)
  WHERE key_algorithm IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.validFrom.indexName}
  ON certificate_items(valid_from)
  WHERE valid_from IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.validTo.indexName}
  ON certificate_items(valid_to)
  WHERE valid_to IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.issuer.indexName}
  ON certificate_items(issuer)
  WHERE issuer IS NOT NULL;
  ''',

  '''
  CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.subject.indexName}
  ON certificate_items(subject)
  WHERE subject IS NOT NULL;
  ''',
];

enum CertificateItemTrigger {
  validateVaultItemTypeOnInsert(
    'trg_certificate_items_validate_vault_item_type_on_insert',
  ),

  validateVaultItemTypeOnUpdate(
    'trg_certificate_items_validate_vault_item_type_on_update',
  ),

  preventItemIdUpdate('trg_certificate_items_prevent_item_id_update');

  const CertificateItemTrigger(this.triggerName);

  final String triggerName;
}

enum CertificateItemRaise {
  invalidVaultItemType(
    'certificate_items.item_id must reference vault_items.id with type = certificate',
  ),

  itemIdImmutable('certificate_items.item_id is immutable');

  const CertificateItemRaise(this.message);

  final String message;
}

final List<String> certificateItemsTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${CertificateItemTrigger.validateVaultItemTypeOnInsert.triggerName}
  BEFORE INSERT ON certificate_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'certificate'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CertificateItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CertificateItemTrigger.validateVaultItemTypeOnUpdate.triggerName}
  BEFORE UPDATE ON certificate_items
  FOR EACH ROW
  WHEN NOT EXISTS (
    SELECT 1
    FROM vault_items
    WHERE id = NEW.item_id
      AND type = 'certificate'
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CertificateItemRaise.invalidVaultItemType.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${CertificateItemTrigger.preventItemIdUpdate.triggerName}
  BEFORE UPDATE OF item_id ON certificate_items
  FOR EACH ROW
  WHEN NEW.item_id <> OLD.item_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${CertificateItemRaise.itemIdImmutable.message}'
    );
  END;
  ''',
];
