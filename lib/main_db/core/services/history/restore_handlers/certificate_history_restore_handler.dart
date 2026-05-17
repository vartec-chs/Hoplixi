import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/certificate_history_payload.dart';
import 'vault_history_restore_handler.dart';

class CertificateHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  CertificateHistoryRestoreHandler({
    required this.certificateItemsDao,
  });

  final CertificateItemsDao certificateItemsDao;

  @override
  VaultItemType get type => VaultItemType.certificate;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! CertificateHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Certificate restore',
          entity: 'certificate',
        ),
      );
    }

    await certificateItemsDao.upsertCertificateItem(
      CertificateItemsCompanion(
        itemId: Value(base.itemId),
        certificateFormat: Value(payload.certificateFormat),
        certificateFormatOther: Value(payload.certificateFormatOther),
        certificatePem: Value(payload.certificatePem),
        certificateBlob: Value(payload.certificateBlob),
        privateKey: Value(payload.privateKey),
        privateKeyPassword: Value(payload.privateKeyPassword),
        passwordForPfx: Value(payload.passwordForPfx),
        keyAlgorithm: Value(payload.keyAlgorithm),
        keyAlgorithmOther: Value(payload.keyAlgorithmOther),
        keySize: Value(payload.keySize),
        serialNumber: Value(payload.serialNumber),
        issuer: Value(payload.issuer),
        subject: Value(payload.subject),
        validFrom: Value(payload.validFrom),
        validTo: Value(payload.validTo),
      ),
    );

    return const Success(unit);
  }
}
