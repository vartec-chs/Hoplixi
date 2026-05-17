import 'package:hoplixi/main_db/core/services/history/models/history_field_snapshot.dart';

import 'history_payload.dart';
import 'normalized_custom_field.dart';
import 'vault_item_base_history_payload.dart';

class NormalizedHistorySnapshot<TPayload extends HistoryPayload> {
  const NormalizedHistorySnapshot({
    required this.base,
    required this.payload,
    required this.customFields,
    required this.restoreWarnings,
  });

  final VaultItemBaseHistoryPayload base;
  final TPayload payload;
  final List<NormalizedCustomField> customFields;
  final List<String> restoreWarnings;

  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      ...base.diffFields(),
      ...payload.diffFields(),
    ];
  }

  NormalizedHistorySnapshot<TPayload> copyWith({
    VaultItemBaseHistoryPayload? base,
    TPayload? payload,
    List<NormalizedCustomField>? customFields,
    List<String>? restoreWarnings,
  }) {
    return NormalizedHistorySnapshot<TPayload>(
      base: base ?? this.base,
      payload: payload ?? this.payload,
      customFields: customFields ?? this.customFields,
      restoreWarnings: restoreWarnings ?? this.restoreWarnings,
    );
  }
}

typedef AnyNormalizedHistorySnapshot = NormalizedHistorySnapshot<HistoryPayload>;
