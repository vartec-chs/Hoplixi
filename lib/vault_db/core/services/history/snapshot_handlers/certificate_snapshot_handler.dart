import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class CertificateSnapshotHandler implements VaultSnapshotTypeHandler {
  CertificateSnapshotHandler({required this.certificateHistoryDao});

  final CertificateHistoryDao certificateHistoryDao;

  @override
  VaultItemType get type => VaultItemType.certificate;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! CertificateViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Certificate snapshot',
            entity: 'certificate',
          );
        }

        final cert = view.certificate;

        await certificateHistoryDao.insertCertificateHistory(
          CertificateHistoryCompanion.insert(
            historyId: historyId,
            certificateFormat: Value(cert.certificateFormat),
            certificateFormatOther: Value(cert.certificateFormatOther),
            certificatePem: Value(cert.certificatePem),
            certificateBlob: Value(cert.certificateBlob),
            privateKey: Value(includeSecrets ? cert.privateKey : null),
            privateKeyPassword: Value(
              includeSecrets ? cert.privateKeyPassword : null,
            ),
            passwordForPfx: Value(includeSecrets ? cert.passwordForPfx : null),
            keyAlgorithm: Value(cert.keyAlgorithm),
            keyAlgorithmOther: Value(cert.keyAlgorithmOther),
            keySize: Value(cert.keySize),
            serialNumber: Value(cert.serialNumber),
            issuer: Value(cert.issuer),
            subject: Value(cert.subject),
            validFrom: Value(cert.validFrom),
            validTo: Value(cert.validTo),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка сертификата',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
