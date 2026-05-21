import 'package:hoplixi/vault_db/core/repositories/base/certificate_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await certificateHistoryDao
            .getCertificateHistoryByHistoryIds([historyId]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          CertificateHistoryPayload(
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
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории сертификата',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final viewOpt = (await certificateRepository.getViewById(itemId))
            .getOrThrow();
        return viewOpt.fold(
          (view) {
            final item = view.certificate;
            return Some(
              CertificateHistoryPayload(
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
              ),
            );
          },
          () => const None(),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния сертификата',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
