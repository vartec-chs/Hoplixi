import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../../../models/mappers/history/vault_snapshot_history_mapper.dart';

class GenericHistoryCardReader {
  Future<Map<String, VaultHistoryCardDto>> getCardsBySnapshots(
    List<VaultSnapshotHistoryData> snapshots,
  ) async {
    return {
      for (final snapshot in snapshots)
        snapshot.id: GenericHistoryCardDto(
          snapshot: snapshot.toVaultSnapshotCardDto(),
        ),
    };
  }
}
