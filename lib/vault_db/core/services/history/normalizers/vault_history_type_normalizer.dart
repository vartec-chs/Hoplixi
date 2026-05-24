import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';

abstract interface class VaultHistoryTypeNormalizer {
  VaultItemType get type;

  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  });

  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  });
}
