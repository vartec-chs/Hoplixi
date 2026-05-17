import '../db_constraint_descriptor.dart';
import '../../tables/certificate/certificate_items.dart';

final Map<String, DbConstraintDescriptor> certificateRegistry = {
  CertificateItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_item_id_not_blank',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'itemId',
        code: 'certificate.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
  CertificateItemConstraint.certificateContentRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_content_required',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'certificatePem',
        code: 'certificate.content.required',
        message: 'Сертификат должен содержать PEM текст или бинарные данные',
      ),
  CertificateItemConstraint.certificatePemNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_certificate_pem_not_blank',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'certificatePem',
        code: 'certificate.pem.not_blank',
        message: 'PEM текст сертификата не может состоять из одних пробелов',
      ),
  CertificateItemConstraint.pemFormatRequiresPem.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_pem_format_requires_pem',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'certificatePem',
        code: 'certificate.pem.required_for_format',
        message: 'Для формата PEM необходимо указать текст сертификата',
      ),
  CertificateItemConstraint.binaryFormatRequiresBlob.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_binary_format_requires_blob',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'certificateBlob',
        code: 'certificate.blob.required_for_format',
        message: 'Для бинарного формата необходимо загрузить файл сертификата',
      ),
  CertificateItemConstraint.keySizePositive.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_key_size_positive',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'keySize',
        code: 'certificate.key_size.not_positive',
        message: 'Размер ключа должен быть положительным числом',
      ),
  CertificateItemConstraint.serialNumberNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_serial_number_not_blank',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'serialNumber',
        code: 'certificate.serial_number.not_blank',
        message: 'Серийный номер не может быть пустым',
      ),
  CertificateItemConstraint.issuerNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_issuer_not_blank',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'issuer',
        code: 'certificate.issuer.not_blank',
        message: 'Издатель (Issuer) не может быть пустым',
      ),
  CertificateItemConstraint.subjectNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_subject_not_blank',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'subject',
        code: 'certificate.subject.not_blank',
        message: 'Субъект (Subject) не может быть пустым',
      ),
  CertificateItemConstraint.validRange.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_certificate_items_valid_range',
        entity: 'certificate',
        table: 'certificate_items',
        field: 'validTo',
        code: 'certificate.valid_range.invalid',
        message: 'Дата окончания действия должна быть позже даты начала',
      ),
};
