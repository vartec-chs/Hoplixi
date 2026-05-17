import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';

part 'certificate_history_dao.g.dart';

@DriftAccessor(tables: [CertificateHistory])
class CertificateHistoryDao extends DatabaseAccessor<MainStore>
    with _$CertificateHistoryDaoMixin {
  CertificateHistoryDao(super.db);

  Future<void> insertCertificateHistory(CertificateHistoryCompanion companion) {
    return into(certificateHistory).insert(companion);
  }

  Future<CertificateHistoryData?> getCertificateHistoryByHistoryId(
    String historyId,
  ) {
    return (select(
      certificateHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).getSingleOrNull();
  }

  Future<bool> existsCertificateHistoryByHistoryId(String historyId) async {
    final row =
        await (selectOnly(certificateHistory)
              ..addColumns([certificateHistory.historyId])
              ..where(certificateHistory.historyId.equals(historyId)))
            .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteCertificateHistoryByHistoryId(String historyId) {
    return (delete(
      certificateHistory,
    )..where((tbl) => tbl.historyId.equals(historyId))).go();
  }

  // --- HISTORY CARD BATCH METHODS ---
  Future<List<CertificateHistoryData>> getCertificateHistoryByHistoryIds(
    List<String> historyIds,
  ) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(
      certificateHistory,
    )..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, CertificateHistoryCardDataDto>>
  getCertificateHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasCertificatePemExpr = certificateHistory.certificatePem.isNotNull();
    final hasCertificateBlobExpr = certificateHistory.certificateBlob
        .isNotNull();
    final hasPrivateKeyExpr = certificateHistory.privateKey.isNotNull();
    final hasPrivateKeyPasswordExpr = certificateHistory.privateKeyPassword
        .isNotNull();
    final hasPasswordForPfxExpr = certificateHistory.passwordForPfx.isNotNull();
    final query = selectOnly(certificateHistory)
      ..addColumns([
        certificateHistory.historyId,
        certificateHistory.certificateFormat,
        certificateHistory.keyAlgorithm,
        certificateHistory.keySize,
        certificateHistory.serialNumber,
        certificateHistory.issuer,
        certificateHistory.subject,
        certificateHistory.validFrom,
        certificateHistory.validTo,
        hasCertificatePemExpr,
        hasCertificateBlobExpr,
        hasPrivateKeyExpr,
        hasPrivateKeyPasswordExpr,
        hasPasswordForPfxExpr,
      ])
      ..where(certificateHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(certificateHistory.historyId)!: CertificateHistoryCardDataDto(
          certificateFormat: row.readWithConverter<CertificateFormat?, String>(
            certificateHistory.certificateFormat,
          ),
          keyAlgorithm: row.readWithConverter<CertificateKeyAlgorithm?, String>(
            certificateHistory.keyAlgorithm,
          ),
          keySize: row.read(certificateHistory.keySize),
          serialNumber: row.read(certificateHistory.serialNumber),
          issuer: row.read(certificateHistory.issuer),
          subject: row.read(certificateHistory.subject),
          validFrom: row.read(certificateHistory.validFrom),
          validTo: row.read(certificateHistory.validTo),
          hasCertificatePem: row.read(hasCertificatePemExpr) ?? false,
          hasCertificateBlob: row.read(hasCertificateBlobExpr) ?? false,
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
          hasPrivateKeyPassword: row.read(hasPrivateKeyPasswordExpr) ?? false,
          hasPasswordForPfx: row.read(hasPasswordForPfxExpr) ?? false,
        ),
    };
  }

  Future<String?> getCertificatePemByHistoryId(String historyId) async {
    final row =
        await (selectOnly(certificateHistory)
              ..addColumns([certificateHistory.certificatePem])
              ..where(certificateHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(certificateHistory.certificatePem);
  }

  Future<Uint8List?> getCertificateBlobByHistoryId(String historyId) async {
    final row =
        await (selectOnly(certificateHistory)
              ..addColumns([certificateHistory.certificateBlob])
              ..where(certificateHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(certificateHistory.certificateBlob);
  }

  Future<String?> getPrivateKeyByHistoryId(String historyId) async {
    final row =
        await (selectOnly(certificateHistory)
              ..addColumns([certificateHistory.privateKey])
              ..where(certificateHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(certificateHistory.privateKey);
  }

  Future<String?> getPrivateKeyPasswordByHistoryId(String historyId) async {
    final row =
        await (selectOnly(certificateHistory)
              ..addColumns([certificateHistory.privateKeyPassword])
              ..where(certificateHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(certificateHistory.privateKeyPassword);
  }

  Future<String?> getPasswordForPfxByHistoryId(String historyId) async {
    final row =
        await (selectOnly(certificateHistory)
              ..addColumns([certificateHistory.passwordForPfx])
              ..where(certificateHistory.historyId.equals(historyId)))
            .getSingleOrNull();
    return row?.read(certificateHistory.passwordForPfx);
  }
}
