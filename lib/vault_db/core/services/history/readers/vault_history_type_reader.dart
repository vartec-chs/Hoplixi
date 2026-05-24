import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../../scheme/tables/vault_items/vault_items.dart';
import '../../../models/dto_history/cards/vault_history_card_dto.dart';

abstract interface class VaultHistoryTypeReader {
  VaultItemType get type;

  Future<Map<String, VaultHistoryCardDto>> getCardsBySnapshots(
    List<VaultSnapshotHistoryData> snapshots,
  );
}
