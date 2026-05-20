import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class DocumentHistoryPayload extends HistoryPayload {
  const DocumentHistoryPayload();

  @override
  VaultItemType get type => VaultItemType.document;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return const [];
  }
}
