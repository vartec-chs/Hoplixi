import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/document_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class DocumentHistoryNormalizer implements VaultHistoryTypeNormalizer {
  @override
  VaultItemType get type => VaultItemType.document;

  @override
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    return const DocumentHistoryPayload();
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    return const DocumentHistoryPayload();
  }
}
