import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';

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
