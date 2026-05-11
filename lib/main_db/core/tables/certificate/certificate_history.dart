import 'package:drift/drift.dart';

import '../vault_items/vault_item_history.dart';
import 'certificate_items.dart';

@DataClassName('CertificateHistoryData')
class CertificateHistory extends Table {
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Формат сертификата snapshot.
  TextColumn get certificateFormat =>
      textEnum<CertificateFormat>().nullable()();

  /// Дополнительный формат, если certificateFormat = other.
  TextColumn get certificateFormatOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// PEM/текстовое представление сертификата snapshot.
  TextColumn get certificatePem => text().nullable()();

  /// DER/PFX/PKCS#12 или другой бинарный контейнер snapshot.
  BlobColumn get certificateBlob => blob().nullable()();

  /// Приватный ключ snapshot.
  ///
  /// Nullable intentionally:
  /// history may store metadata-only snapshots depending on secret history policy.
  TextColumn get privateKey => text().nullable()();

  /// Пароль от privateKey snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get privateKeyPassword => text().nullable()();

  /// Пароль от PFX/PKCS#12 snapshot.
  ///
  /// Nullable intentionally.
  TextColumn get passwordForPfx => text().nullable()();

  /// Алгоритм ключа snapshot.
  TextColumn get keyAlgorithm =>
      textEnum<CertificateKeyAlgorithm>().nullable()();

  /// Дополнительный алгоритм, если keyAlgorithm = other.
  TextColumn get keyAlgorithmOther =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Размер ключа snapshot.
  IntColumn get keySize => integer().nullable()();

  /// Серийный номер сертификата snapshot.
  TextColumn get serialNumber =>
      text().withLength(min: 1, max: 255).nullable()();

  /// Issuer сертификата snapshot.
  TextColumn get issuer => text().nullable()();

  /// Subject сертификата snapshot.
  TextColumn get subject => text().nullable()();

  /// Дата начала действия сертификата snapshot.
  DateTimeColumn get validFrom => dateTime().nullable()();

  /// Дата окончания действия сертификата snapshot.
  DateTimeColumn get validTo => dateTime().nullable()();

  /// OCSP URL snapshot.
  TextColumn get ocspUrl => text().withLength(min: 1, max: 2048).nullable()();

  /// CRL URL snapshot.
  TextColumn get crlUrl => text().withLength(min: 1, max: 2048).nullable()();

  /// Дополнительные метаданные snapshot.
  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'certificate_history';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${CertificateHistoryConstraint.certificateContentRequired.constraintName}
    CHECK (
      certificate_pem IS NOT NULL
      OR certificate_blob IS NOT NULL
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.certificatePemNotBlank.constraintName}
    CHECK (
      certificate_pem IS NULL
      OR length(trim(certificate_pem)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.certificateFormatOtherRequired.constraintName}
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
    CONSTRAINT ${CertificateHistoryConstraint.certificateFormatOtherMustBeNull.constraintName}
    CHECK (
      certificate_format = 'other'
      OR certificate_format_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.keyAlgorithmOtherRequired.constraintName}
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
    CONSTRAINT ${CertificateHistoryConstraint.keyAlgorithmOtherMustBeNull.constraintName}
    CHECK (
      key_algorithm = 'other'
      OR key_algorithm_other IS NULL
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.keySizePositive.constraintName}
    CHECK (
      key_size IS NULL
      OR key_size > 0
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.serialNumberNotBlank.constraintName}
    CHECK (
      serial_number IS NULL
      OR length(trim(serial_number)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.issuerNotBlank.constraintName}
    CHECK (
      issuer IS NULL
      OR length(trim(issuer)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.subjectNotBlank.constraintName}
    CHECK (
      subject IS NULL
      OR length(trim(subject)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.validRange.constraintName}
    CHECK (
      valid_from IS NULL
      OR valid_to IS NULL
      OR valid_from <= valid_to
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.ocspUrlNotBlank.constraintName}
    CHECK (
      ocsp_url IS NULL
      OR length(trim(ocsp_url)) > 0
    )
    ''',

    '''
    CONSTRAINT ${CertificateHistoryConstraint.crlUrlNotBlank.constraintName}
    CHECK (
      crl_url IS NULL
      OR length(trim(crl_url)) > 0
    )
    ''',
  ];
}

enum CertificateHistoryConstraint {
  certificateContentRequired('chk_certificate_history_content_required'),

  certificatePemNotBlank('chk_certificate_history_certificate_pem_not_blank'),

  certificateFormatOtherRequired(
    'chk_certificate_history_certificate_format_other_required',
  ),

  certificateFormatOtherMustBeNull(
    'chk_certificate_history_certificate_format_other_must_be_null',
  ),

  keyAlgorithmOtherRequired(
    'chk_certificate_history_key_algorithm_other_required',
  ),

  keyAlgorithmOtherMustBeNull(
    'chk_certificate_history_key_algorithm_other_must_be_null',
  ),

  keySizePositive('chk_certificate_history_key_size_positive'),

  serialNumberNotBlank('chk_certificate_history_serial_number_not_blank'),

  issuerNotBlank('chk_certificate_history_issuer_not_blank'),

  subjectNotBlank('chk_certificate_history_subject_not_blank'),

  validRange('chk_certificate_history_valid_range'),

  ocspUrlNotBlank('chk_certificate_history_ocsp_url_not_blank'),

  crlUrlNotBlank('chk_certificate_history_crl_url_not_blank');

  const CertificateHistoryConstraint(this.constraintName);

  final String constraintName;
}

enum CertificateHistoryIndex {
  certificateFormat('idx_certificate_history_certificate_format'),
  keyAlgorithm('idx_certificate_history_key_algorithm'),
  validFrom('idx_certificate_history_valid_from'),
  validTo('idx_certificate_history_valid_to'),
  issuer('idx_certificate_history_issuer'),
  subject('idx_certificate_history_subject');

  const CertificateHistoryIndex(this.indexName);

  final String indexName;
}

final List<String> certificateHistoryTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${CertificateHistoryIndex.certificateFormat.indexName} ON certificate_history(certificate_format);',
  'CREATE INDEX IF NOT EXISTS ${CertificateHistoryIndex.keyAlgorithm.indexName} ON certificate_history(key_algorithm);',
  'CREATE INDEX IF NOT EXISTS ${CertificateHistoryIndex.validFrom.indexName} ON certificate_history(valid_from);',
  'CREATE INDEX IF NOT EXISTS ${CertificateHistoryIndex.validTo.indexName} ON certificate_history(valid_to);',
  'CREATE INDEX IF NOT EXISTS ${CertificateHistoryIndex.issuer.indexName} ON certificate_history(issuer);',
  'CREATE INDEX IF NOT EXISTS ${CertificateHistoryIndex.subject.indexName} ON certificate_history(subject);',
];
