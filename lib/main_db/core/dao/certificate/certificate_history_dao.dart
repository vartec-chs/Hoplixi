import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/certificate/certificate_history.dart';

part 'certificate_history_dao.g.dart';

@DriftAccessor(tables: [CertificateHistory])
class CertificateHistoryDao extends DatabaseAccessor<MainStore>
    with _$CertificateHistoryDaoMixin {
  CertificateHistoryDao(super.db);

  Future<void> insertCertificateHistory(CertificateHistoryCompanion companion) {
    return into(certificateHistory).insert(companion);
  }

  Future<CertificateHistoryData?> getCertificateHistoryByHistoryId(
      String historyId) {
    return (select(certificateHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsCertificateHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(certificateHistory)
          ..addColumns([certificateHistory.historyId])
          ..where(certificateHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteCertificateHistoryByHistoryId(String historyId) {
    return (delete(certificateHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
