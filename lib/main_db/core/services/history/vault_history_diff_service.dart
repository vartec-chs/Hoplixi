import 'package:hoplixi/main_db/core/main_store.dart';

import '../../tables/tables.dart';
import '../../tables/vault_items/vault_item_custom_fields.dart';
import 'package:collection/collection.dart';
import '../../models/dto_history/cards/vault_history_revision_detail_dto.dart';
import 'vault_history_normalized_loader.dart';
import 'history_field_label_resolver.dart';

class VaultHistoryDiffService {
  VaultHistoryDiffService({
    required this.labelResolver,
  });

  final HistoryFieldLabelResolver labelResolver;

  List<VaultHistoryFieldDiffDto> buildFieldDiffs({
    required NormalizedHistorySnapshot current,
    required NormalizedHistorySnapshot replacement,
  }) {
    final diffs = <VaultHistoryFieldDiffDto>[];
    final allKeys = {...current.fields.keys, ...replacement.fields.keys};

    for (final key in allKeys) {
      final oldVal = current.fields[key];
      final newVal = replacement.fields[key];

      if (oldVal == newVal) continue;

      final isSensitive = current.sensitiveKeys.contains(key) || 
                         replacement.sensitiveKeys.contains(key);

      diffs.add(VaultHistoryFieldDiffDto(
        fieldKey: key,
        label: labelResolver.labelFor(
          type: replacement.snapshot.type,
          fieldKey: key,
        ),
        oldValue: isSensitive ? '••••••' : oldVal,
        newValue: isSensitive ? '••••••' : newVal,
        changeType: _determineChangeType(oldVal, newVal),
        isSensitive: isSensitive,
      ));
    }

    return diffs;
  }

  List<VaultHistoryFieldDiffDto> buildCustomFieldDiffs({
    required NormalizedHistorySnapshot current,
    required NormalizedHistorySnapshot replacement,
  }) {
    final diffs = <VaultHistoryFieldDiffDto>[];

    final currentFields = (current.customFields as List).cast<VaultItemCustomFieldsHistoryData>();
    final replacementFields = (replacement.customFields as List).cast<VaultItemCustomFieldsHistoryData>();

    final allIds = <String>{
      ...currentFields.map((e) => e.originalFieldId ?? e.id),
      ...replacementFields.map((e) => e.originalFieldId ?? e.id),
    };

    for (final id in allIds) {
      final oldF = currentFields.firstWhereOrNull((e) => (e.originalFieldId ?? e.id) == id);
      final newF = replacementFields.firstWhereOrNull((e) => (e.originalFieldId ?? e.id) == id);

      if (oldF == null && newF == null) continue;

      final label = newF?.label ?? oldF!.label;
      final isSensitive = (oldF?.isSecret == true || oldF?.fieldType == CustomFieldType.concealed) ||
                          (newF?.isSecret == true || newF?.fieldType == CustomFieldType.concealed);

      final oldVal = oldF?.value;
      final newVal = newF?.value;

      if (oldF != null && newF != null && oldVal == newVal) {
        // Also check if label or field type changed if needed, but standard diff focuses on value
        continue;
      }

      diffs.add(VaultHistoryFieldDiffDto(
        fieldKey: id,
        label: label,
        oldValue: isSensitive ? '••••••' : oldVal,
        newValue: isSensitive ? '••••••' : newVal,
        changeType: _determineChangeType(oldVal, newVal),
        isSensitive: isSensitive,
      ));
    }

    return diffs;
  }

  HistoryFieldChangeType _determineChangeType(Object? oldVal, Object? newVal) {
    if (oldVal == null && newVal != null) return HistoryFieldChangeType.added;
    if (oldVal != null && newVal == null) return HistoryFieldChangeType.removed;
    return HistoryFieldChangeType.changed;
  }
}
