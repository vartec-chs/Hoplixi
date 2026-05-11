import 'package:drift/drift.dart';

import '../vault_items/vault_items.dart';

enum CertificateFormat { pem, der, pfx, pkcs12, other }

enum CertificateKeyAlgorithm { rsa, ecdsa, ed25519, dsa, other }

@DataClassName('CertificateItemsData')
class CertificateItems extends Table {
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

  /// Дополнительные метаданные в JSON-формате.
  ///
  /// Сюда можно положить keyUsage, extensions, SAN, fingerprint,
  /// certificate chain info и другие редко используемые детали.
  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'certificate_items';

  @override
  List<String> get customConstraints => [
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
    CONSTRAINT ${CertificateItemConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
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
    CONSTRAINT ${CertificateItemConstraint.crlUrlNotBlank.constraintName}
    CHECK (
      crl_url IS NULL
      OR length(trim(crl_url)) > 0
    )
    ''',
  ];
}

enum CertificateItemConstraint {
  certificateContentRequired('chk_certificate_items_content_required'),

  certificatePemNotBlank('chk_certificate_items_certificate_pem_not_blank'),

  certificateFormatOtherRequired(
    'chk_certificate_items_certificate_format_other_required',
  ),

  certificateFormatOtherMustBeNull(
    'chk_certificate_items_certificate_format_other_must_be_null',
  ),

  keyAlgorithmOtherRequired(
    'chk_certificate_items_key_algorithm_other_required',
  ),

  keyAlgorithmOtherMustBeNull(
    'chk_certificate_items_key_algorithm_other_must_be_null',
  ),

  keySizePositive('chk_certificate_items_key_size_positive'),

  serialNumberNotBlank('chk_certificate_items_serial_number_not_blank'),

  issuerNotBlank('chk_certificate_items_issuer_not_blank'),

  subjectNotBlank('chk_certificate_items_subject_not_blank'),

  validRange('chk_certificate_items_valid_range'),

  ocspUrlNotBlank('chk_certificate_items_ocsp_url_not_blank'),

  crlUrlNotBlank('chk_certificate_items_crl_url_not_blank');

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
  'CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.certificateFormat.indexName} ON certificate_items(certificate_format);',
  'CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.keyAlgorithm.indexName} ON certificate_items(key_algorithm);',
  'CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.validFrom.indexName} ON certificate_items(valid_from);',
  'CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.validTo.indexName} ON certificate_items(valid_to);',
  'CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.issuer.indexName} ON certificate_items(issuer);',
  'CREATE INDEX IF NOT EXISTS ${CertificateItemIndex.subject.indexName} ON certificate_items(subject);',
];
