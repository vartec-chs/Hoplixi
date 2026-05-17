import 'dart:typed_data';

import '../../../tables/certificate/certificate_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class CertificateHistoryPayload extends HistoryPayload {
  const CertificateHistoryPayload({
    this.certificateFormat,
    this.certificateFormatOther,
    this.certificatePem,
    this.certificateBlob,
    this.privateKey,
    this.privateKeyPassword,
    this.passwordForPfx,
    this.keyAlgorithm,
    this.keyAlgorithmOther,
    this.keySize,
    this.serialNumber,
    this.issuer,
    this.subject,
    this.validFrom,
    this.validTo,
  });

  final CertificateFormat? certificateFormat;
  final String? certificateFormatOther;
  final String? certificatePem;
  final Uint8List? certificateBlob;
  final String? privateKey;
  final String? privateKeyPassword;
  final String? passwordForPfx;
  final CertificateKeyAlgorithm? keyAlgorithm;
  final String? keyAlgorithmOther;
  final int? keySize;
  final String? serialNumber;
  final String? issuer;
  final String? subject;
  final DateTime? validFrom;
  final DateTime? validTo;

  @override
  VaultItemType get type => VaultItemType.certificate;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'certificate.certificateFormat',
        label: 'Format',
        value: certificateFormat?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.certificateFormatOther',
        label: 'Format other',
        value: certificateFormatOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.certificatePem',
        label: 'PEM',
        value: certificatePem,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<Uint8List>(
        key: 'certificate.certificateBlob',
        label: 'Blob',
        value: certificateBlob,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.privateKey',
        label: 'Private key',
        value: privateKey,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.privateKeyPassword',
        label: 'Private key password',
        value: privateKeyPassword,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.passwordForPfx',
        label: 'PFX password',
        value: passwordForPfx,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.keyAlgorithm',
        label: 'Key algorithm',
        value: keyAlgorithm?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.keyAlgorithmOther',
        label: 'Key algorithm other',
        value: keyAlgorithmOther,
      ),
      HistoryFieldSnapshot<int>(
        key: 'certificate.keySize',
        label: 'Key size',
        value: keySize,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.serialNumber',
        label: 'Serial number',
        value: serialNumber,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.issuer',
        label: 'Issuer',
        value: issuer,
      ),
      HistoryFieldSnapshot<String>(
        key: 'certificate.subject',
        label: 'Subject',
        value: subject,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'certificate.validFrom',
        label: 'Valid from',
        value: validFrom,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'certificate.validTo',
        label: 'Valid to',
        value: validTo,
      ),
    ];
  }
}
