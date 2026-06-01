import '../../../scheme/tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class RecoveryCodesHistoryPayload extends HistoryPayload {
  const RecoveryCodesHistoryPayload({this.generatedAt, this.oneTime});

  final DateTime? generatedAt;
  final bool? oneTime;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<DateTime>(
        key: 'recoveryCodes.generatedAt',
        label: 'Generated at',
        value: generatedAt,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'recoveryCodes.oneTime',
        label: 'One time',
        value: oneTime,
      ),
    ];
  }
}
