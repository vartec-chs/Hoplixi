import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';

abstract interface class VaultHistoryTypeNormalizer {
  VaultItemType get type;

  Future<HistoryPayload?> normalizeHistory({required String historyId});

  Future<HistoryPayload?> normalizeCurrent({required String itemId});
}
