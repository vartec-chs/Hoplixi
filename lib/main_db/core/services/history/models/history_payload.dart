import '../../../tables/vault_items/vault_items.dart';
import 'history_field_snapshot.dart';

abstract class HistoryPayload {
  const HistoryPayload();

  VaultItemType get type;

  List<HistoryFieldSnapshot<Object?>> diffFields();
}
