import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class EmptyHistoryPayload extends HistoryPayload {
  const EmptyHistoryPayload(this.type);

  @override
  final VaultItemType type;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() => const [];
}
