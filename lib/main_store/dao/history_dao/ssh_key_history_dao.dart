import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/ssh_key_history_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/ssh_key_history.dart';
import 'package:hoplixi/main_store/tables/vault_item_history.dart';

part 'ssh_key_history_dao.g.dart';

@DriftAccessor(tables: [VaultItemHistory, SshKeyHistory])
class SshKeyHistoryDao extends DatabaseAccessor<MainStore>
    with _$SshKeyHistoryDaoMixin {
  SshKeyHistoryDao(super.db);

  Future<List<SshKeyHistoryCardDto>> getSshKeyHistoryCardsByOriginalId(
    String sshKeyId,
    int offset,
    int limit,
    String? searchQuery,
  ) async {
    final query = select(vaultItemHistory).join([
      innerJoin(
        sshKeyHistory,
        sshKeyHistory.historyId.equalsExp(vaultItemHistory.id),
      ),
    ]);

    Expression<bool> where =
        vaultItemHistory.itemId.equals(sshKeyId) &
        vaultItemHistory.type.equalsValue(VaultItemType.sshKey);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      where =
          where &
          (vaultItemHistory.name.like(q) |
              sshKeyHistory.keyType.like(q) |
              sshKeyHistory.fingerprint.like(q) |
              sshKeyHistory.usage.like(q));
    }

    query
      ..where(where)
      ..orderBy([OrderingTerm.desc(vaultItemHistory.actionAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapToCard).toList();
  }

  Future<int> countSshKeyHistoryByOriginalId(
    String sshKeyId,
    String? searchQuery,
  ) async {
    final countExpr = vaultItemHistory.id.count();

    final query = selectOnly(vaultItemHistory)
      ..join([
        innerJoin(
          sshKeyHistory,
          sshKeyHistory.historyId.equalsExp(vaultItemHistory.id),
        ),
      ])
      ..addColumns([countExpr])
      ..where(
        vaultItemHistory.itemId.equals(sshKeyId) &
            vaultItemHistory.type.equalsValue(VaultItemType.sshKey),
      );

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = '%$searchQuery%';
      query.where(
        vaultItemHistory.name.like(q) |
            sshKeyHistory.keyType.like(q) |
            sshKeyHistory.fingerprint.like(q) |
            sshKeyHistory.usage.like(q),
      );
    }

    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<int> deleteSshKeyHistoryById(String historyId) {
    return (delete(
      vaultItemHistory,
    )..where((h) => h.id.equals(historyId))).go();
  }

  Future<int> deleteSshKeyHistoryBySshKeyId(String sshKeyId) {
    return (delete(vaultItemHistory)..where(
          (h) =>
              h.itemId.equals(sshKeyId) &
              h.type.equalsValue(VaultItemType.sshKey),
        ))
        .go();
  }

  SshKeyHistoryCardDto _mapToCard(TypedResult row) {
    final history = row.readTable(vaultItemHistory);
    final ssh = row.readTable(sshKeyHistory);

    return SshKeyHistoryCardDto(
      id: history.id,
      originalSshKeyId: history.itemId,
      action: history.action.value,
      name: history.name,
      keyType: ssh.keyType,
      fingerprint: ssh.fingerprint,
      addedToAgent: ssh.addedToAgent,
      usage: ssh.usage,
      actionAt: history.actionAt,
    );
  }
}
