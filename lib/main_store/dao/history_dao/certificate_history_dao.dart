import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/certificate_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/certificate_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'certificate_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, CertificateHistory])
class CertificateHistoryDao extends DatabaseAccessor<MainStore>
    with _$CertificateHistoryDaoMixin {
  CertificateHistoryDao(super.db);

  Future<List<CertificateHistoryCardDto>>
  getCertificateHistoryCardsByOriginalId(
    String certificateId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        certificateHistory,
        certificateHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(certificateId) &
        vaultItemHistory.type.equalsValue(VaultItemType.certificate);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              certificateHistory.issuer.like(q) |
              certificateHistory.subject.like(q) |
              certificateHistory.serialNumber.like(q) |
              certificateHistory.fingerprint.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countCertificateHistoryByOriginalId(
    String certificateId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          certificateHistory,
          certificateHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(certificateId) &
            vaultItemHistory.type.equalsValue(VaultItemType.certificate),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            certificateHistory.issuer.like(q) |
            certificateHistory.subject.like(q) |
            certificateHistory.serialNumber.like(q) |
            certificateHistory.fingerprint.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteCertificateHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteCertificateHistoryByCertificateId(String certificateId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(certificateId) &
              h.type.equalsValue(VaultItemType.certificate),
        ))
        .go();
  }

  CertificateHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final cert = row.readTable(certificateHistory);

    return CertificateHistoryCardDto(
      id: history.id,
      originalCertificateId: history.itemId,
      action: history.action.value,
      name: history.name,
      issuer: cert.issuer,
      subject: cert.subject,
      serialNumber: cert.serialNumber,
      fingerprint: cert.fingerprint,
      validTo: cert.validTo,
      autoRenew: cert.autoRenew,
      actionAt: history.actionAt,
    );
  }
}
