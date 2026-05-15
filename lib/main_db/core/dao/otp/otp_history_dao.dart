import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/otp/otp_history.dart';

part 'otp_history_dao.g.dart';

@DriftAccessor(tables: [OtpHistory])
class OtpHistoryDao extends DatabaseAccessor<MainStore>
    with _$OtpHistoryDaoMixin {
  OtpHistoryDao(super.db);

  Future<void> insertOtpHistory(OtpHistoryCompanion companion) {
    return into(otpHistory).insert(companion);
  }

  Future<OtpHistoryData?> getOtpHistoryByHistoryId(String historyId) {
    return (select(otpHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsOtpHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(otpHistory)
          ..addColumns([otpHistory.historyId])
          ..where(otpHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteOtpHistoryByHistoryId(String historyId) {
    return (delete(otpHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }
}
