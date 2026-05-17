import 'package:hoplixi/main_db/core/main_store.dart';

import '../../../models/dto_history/cards/cards_exports.dart';
import '../../../models/mappers/history/vault_snapshot_history_mapper.dart';
import '../../../tables/vault_items/vault_items.dart';
import 'vault_history_type_reader.dart';

class DocumentHistoryCardReader implements VaultHistoryTypeReader {
  @override
  VaultItemType get type => VaultItemType.document;

  @override
  Future<Map<String, VaultHistoryCardDto>> getCardsBySnapshots(
    List<VaultSnapshotHistoryData> snapshots,
  ) async {
    return {
      for (final snapshot in snapshots)
        snapshot.id: DocumentHistoryCardDto(
          snapshot: snapshot.toVaultSnapshotCardDto(),
        ),
    };
  }
}
