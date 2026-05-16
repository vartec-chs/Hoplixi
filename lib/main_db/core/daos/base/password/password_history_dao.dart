import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';

import '../../../main_store.dart';
import '../../../tables/password/password_history.dart';

part 'password_history_dao.g.dart';

@DriftAccessor(tables: [PasswordHistory])
class PasswordHistoryDao extends DatabaseAccessor<MainStore>
    with _$PasswordHistoryDaoMixin {
  PasswordHistoryDao(super.db);

  Future<void> insertPasswordHistory(PasswordHistoryCompanion companion) {
    return into(passwordHistory).insert(companion);
  }

  Future<PasswordHistoryData?> getPasswordHistoryByHistoryId(String historyId) {
    return (select(passwordHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .getSingleOrNull();
  }

  Future<bool> existsPasswordHistoryByHistoryId(String historyId) async {
    final row = await (selectOnly(passwordHistory)
          ..addColumns([passwordHistory.historyId])
          ..where(passwordHistory.historyId.equals(historyId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deletePasswordHistoryByHistoryId(String historyId) {
    return (delete(passwordHistory)
          ..where((tbl) => tbl.historyId.equals(historyId)))
        .go();
  }


  // --- HISTORY CARD BATCH METHODS ---
  Future<List<PasswordHistoryData>> getPasswordHistoryByHistoryIds(List<String> historyIds) {
    if (historyIds.isEmpty) return Future.value(const []);
    return (select(passwordHistory)..where((tbl) => tbl.historyId.isIn(historyIds))).get();
  }

  Future<Map<String, PasswordHistoryCardDataDto>> getPasswordHistoryCardDataByHistoryIds(List<String> historyIds) async {
    if (historyIds.isEmpty) return const {};

    final hasPasswordExpr = passwordHistory.password.isNotNull();
    final query = selectOnly(passwordHistory)
      ..addColumns([
        passwordHistory.historyId,
        passwordHistory.login,
        passwordHistory.email,
        passwordHistory.url,
        passwordHistory.expiresAt,
        hasPasswordExpr,
      ])
      ..where(passwordHistory.historyId.isIn(historyIds));

    final rows = await query.get();

    return {
      for (final row in rows)
        row.read(passwordHistory.historyId)!: PasswordHistoryCardDataDto(
          login: row.read(passwordHistory.login),
          email: row.read(passwordHistory.email),
          url: row.read(passwordHistory.url),
          expiresAt: row.read(passwordHistory.expiresAt),
          hasPassword: row.read(hasPasswordExpr) ?? false,
        ),
    };
  }

  Future<String?> getPasswordByHistoryId(String historyId) async {
    final row = await (selectOnly(passwordHistory)
          ..addColumns([passwordHistory.password])
          ..where(passwordHistory.historyId.equals(historyId)))
        .getSingleOrNull();
    return row?.read(passwordHistory.password);
  }

}
