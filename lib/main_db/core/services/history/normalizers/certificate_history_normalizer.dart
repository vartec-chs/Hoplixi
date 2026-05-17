import 'package:hoplixi/main_db/core/repositories/base/certificate_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/certificate_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class CertificateHistoryNormalizer implements VaultHistoryTypeNormalizer {
  CertificateHistoryNormalizer({
    required this.certificateHistoryDao,
    required this.certificateRepository,
  });

  final CertificateHistoryDao certificateHistoryDao;
  final CertificateRepository certificateRepository;

  @override
  VaultItemType get type => VaultItemType.certificate;

  @override
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await certificateHistoryDao.getCertificateHistoryByHistoryIds([
      historyId,
    ]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return CertificateHistoryPayload(
      certificateFormat: item.certificateFormat,
      certificateFormatOther: item.certificateFormatOther,
      certificatePem: item.certificatePem,
      certificateBlob: item.certificateBlob,
      privateKey: item.privateKey,
      privateKeyPassword: item.privateKeyPassword,
      passwordForPfx: item.passwordForPfx,
      keyAlgorithm: item.keyAlgorithm,
      keyAlgorithmOther: item.keyAlgorithmOther,
      keySize: item.keySize,
      serialNumber: item.serialNumber,
      issuer: item.issuer,
      subject: item.subject,
      validFrom: item.validFrom,
      validTo: item.validTo,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await certificateRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.certificate;

    return CertificateHistoryPayload(
      certificateFormat: item.certificateFormat,
      certificateFormatOther: item.certificateFormatOther,
      certificatePem: item.certificatePem,
      certificateBlob: item.certificateBlob,
      privateKey: item.privateKey,
      privateKeyPassword: item.privateKeyPassword,
      passwordForPfx: item.passwordForPfx,
      keyAlgorithm: item.keyAlgorithm,
      keyAlgorithmOther: item.keyAlgorithmOther,
      keySize: item.keySize,
      serialNumber: item.serialNumber,
      issuer: item.issuer,
      subject: item.subject,
      validFrom: item.validFrom,
      validTo: item.validTo,
    );
  }
}
