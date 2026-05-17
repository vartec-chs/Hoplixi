import 'package:hoplixi/main_db/core/main_store.dart';

import '../../../tables/vault_items/vault_items.dart';
import '../../../models/dto_history/cards/vault_history_card_dto.dart';

abstract interface class VaultHistoryTypeReader {
  VaultItemType get type;

  Future<Map<String, VaultHistoryCardDto>> getCardsBySnapshots(
    List<VaultSnapshotHistoryData> snapshots,
  );
}
