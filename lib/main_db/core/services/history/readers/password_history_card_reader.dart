import 'package:hoplixi/main_db/core/main_store.dart';

import '../../../daos/daos.dart';
import '../../../models/dto_history/cards/cards_exports.dart';
import '../../../models/mappers/history/vault_snapshot_history_mapper.dart';
import '../../../tables/vault_items/vault_items.dart';
import 'vault_history_type_reader.dart';

class PasswordHistoryCardReader implements VaultHistoryTypeReader {
  PasswordHistoryCardReader({required this.passwordHistoryDao});

  final PasswordHistoryDao passwordHistoryDao;

  @override
  VaultItemType get type => VaultItemType.password;

  @override
  Future<Map<String, VaultHistoryCardDto>> getCardsBySnapshots(
    List<VaultSnapshotHistoryData> snapshots,
  ) async {
    if (snapshots.isEmpty) return const {};

    final historyIds = snapshots.map((e) => e.id).toList();

    final dataByHistoryId = await passwordHistoryDao
        .getPasswordHistoryCardDataByHistoryIds(historyIds);

    final result = <String, VaultHistoryCardDto>{};

    for (final snapshot in snapshots) {
      final data = dataByHistoryId[snapshot.id];

      final snapshotDto = snapshot.toVaultSnapshotCardDto();

      result[snapshot.id] = data == null
          ? GenericHistoryCardDto(snapshot: snapshotDto)
          : PasswordHistoryCardDto(snapshot: snapshotDto, password: data);
    }

    return result;
  }
}
