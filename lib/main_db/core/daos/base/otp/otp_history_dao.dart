import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/tables.dart';

import '../../../main_store.dart';
import '../../../tables/otp/otp_history.dart';

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


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<OtpHistoryData>> getOtpHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(otpHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, OtpHistoryCardDataDto>> getOtpHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasSecretExpr = otpHistory.secret.isNotNull();
    final query = selectOnly(otpHistory)
      ..addColumns([
        otpHistory.historyId,
        otpHistory.type,
        otpHistory.issuer,
        otpHistory.accountName,
        otpHistory.algorithm,
        otpHistory.digits,
        otpHistory.period,
        otpHistory.counter,
        hasSecretExpr,
      ])
      ..where(otpHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(otpHistory.historyId)!: OtpHistoryCardDataDto(
          type: row.readWithConverter<OtpType?, String>(otpHistory.type),
          issuer: row.read(otpHistory.issuer),
          accountName: row.read(otpHistory.accountName),
          algorithm: row.readWithConverter<OtpHashAlgorithm?, String>(otpHistory.algorithm),
          digits: row.read(otpHistory.digits),
          period: row.read(otpHistory.period),
          counter: row.read(otpHistory.counter),
          hasSecret: row.read(hasSecretExpr) ?? false,
        ),
    };
  }

  Future<Uint8List?> getSecretByHistoryId(String historyId) async {
    final row = await (selectOnly(otpHistory)
          ..addColumns([otpHistory.secret])
          ..where(otpHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(otpHistory.secret);
  }

}
