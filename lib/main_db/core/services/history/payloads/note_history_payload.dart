import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class NoteHistoryPayload extends HistoryPayload {
  const NoteHistoryPayload({this.deltaJson, this.content});

  final String? deltaJson;
  final String? content;

  @override
  VaultItemType get type => VaultItemType.note;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'note.deltaJson',
        label: 'Delta JSON',
        value: deltaJson,
      ),
      HistoryFieldSnapshot<String>(
        key: 'note.content',
        label: 'Content',
        value: content,
      ),
    ];
  }
}
