import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class CertificateSnapshotHandler implements VaultSnapshotTypeHandler {
  CertificateSnapshotHandler({required this.certificateHistoryDao});

  final CertificateHistoryDao certificateHistoryDao;

  @override
  VaultItemType get type => VaultItemType.certificate;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! CertificateViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Certificate snapshot',
          entity: 'certificate',
        ),
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

    return const Success(unit);
  }
}
