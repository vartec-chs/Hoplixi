import '../../main_store.dart';
import '../../models/dto/certificate_dto.dart';

extension CertificateItemsDataMapper on CertificateItemsData {
  CertificateDataDto toCertificateDataDto() {
    return CertificateDataDto(
      certificateFormat: certificateFormat,
      certificateFormatOther: certificateFormatOther,
      certificatePem: certificatePem,
      certificateBlob: certificateBlob,
      privateKey: privateKey,
      privateKeyPassword: privateKeyPassword,
      passwordForPfx: passwordForPfx,
      keyAlgorithm: keyAlgorithm,
      keyAlgorithmOther: keyAlgorithmOther,
      keySize: keySize,
      serialNumber: serialNumber,
      issuer: issuer,
      subject: subject,
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  CertificateCardDataDto toCertificateCardDataDto() {
    return CertificateCardDataDto(
      certificateFormat: certificateFormat,
      keyAlgorithm: keyAlgorithm,
      keySize: keySize,
      serialNumber: serialNumber,
      issuer: issuer,
      subject: subject,
      validFrom: validFrom,
      validTo: validTo,
      hasPrivateKey: privateKey?.isNotEmpty ?? false,
      hasCertificateBlob: certificateBlob != null,
      hasPrivateKeyPassword: privateKeyPassword?.isNotEmpty ?? false,
      hasPasswordForPfx: passwordForPfx?.isNotEmpty ?? false,
      hasCertificatePem: certificatePem?.isNotEmpty ?? false,
    );
  }
}
