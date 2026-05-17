import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class RecoveryCodesHistoryPayload extends HistoryPayload {
  const RecoveryCodesHistoryPayload({
    this.codesCount,
    this.usedCount,
    this.generatedAt,
    this.oneTime,
    this.valuesCount,
    this.missingValuesCount,
    this.usedValuesCount,
  });

  final int? codesCount;
  final int? usedCount;
  final DateTime? generatedAt;
  final bool? oneTime;
  final int? valuesCount;
  final int? missingValuesCount;
  final int? usedValuesCount;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<int>(
        key: 'recoveryCodes.codesCount',
        label: 'Codes count',
        value: codesCount,
      ),
      HistoryFieldSnapshot<int>(
        key: 'recoveryCodes.usedCount',
        label: 'Used count',
        value: usedCount,
      ),
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
      HistoryFieldSnapshot<int>(
        key: 'recoveryCodes.valuesCount',
        label: 'Values count',
        value: valuesCount,
      ),
      HistoryFieldSnapshot<int>(
        key: 'recoveryCodes.missingValuesCount',
        label: 'Missing values count',
        value: missingValuesCount,
      ),
      HistoryFieldSnapshot<int>(
        key: 'recoveryCodes.usedValuesCount',
        label: 'Used values count',
        value: usedValuesCount,
      ),
    ];
  }
}
