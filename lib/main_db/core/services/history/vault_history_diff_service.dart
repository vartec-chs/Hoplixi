import 'package:collection/collection.dart';
import 'package:hoplixi/main_db/core/services/history/history_services.dart';

import '../../models/dto_history/cards/vault_history_revision_detail_dto.dart';
import '../../tables/vault_items/vault_item_custom_fields.dart';
import 'vault_history_normalized_loader.dart';

class VaultHistoryDiffService {
  VaultHistoryDiffService();

  List<VaultHistoryFieldDiffDto> buildFieldDiffs({
    required AnyNormalizedHistorySnapshot current,
    required AnyNormalizedHistorySnapshot replacement,
  }) {
    final diffs = <VaultHistoryFieldDiffDto>[];

    final currentFields = {
      for (final field in current.diffFields()) field.key: field,
    };

    final replacementFields = {
      for (final field in replacement.diffFields()) field.key: field,
    };

    final allKeys = {...currentFields.keys, ...replacementFields.keys};

    for (final key in allKeys) {
      final oldF = currentFields[key];
      final newF = replacementFields[key];

      final oldVal = oldF?.value;
      final newVal = newF?.value;

      if (oldVal == newVal) continue;

      final isSensitive =
          (oldF?.isSensitive ?? false) || (newF?.isSensitive ?? false);
      final label = newF?.label ?? oldF?.label ?? key;

      diffs.add(
        VaultHistoryFieldDiffDto(
          fieldKey: key,
          label: label,
          oldValue: isSensitive ? '••••••' : oldVal,
          newValue: isSensitive ? '••••••' : newVal,
          changeType: _determineChangeType(oldVal, newVal),
          isSensitive: isSensitive,
        ),
      );
    }

    return diffs;
  }

  List<VaultHistoryFieldDiffDto> buildCustomFieldDiffs({
    required AnyNormalizedHistorySnapshot current,
    required AnyNormalizedHistorySnapshot replacement,
  }) {
    final diffs = <VaultHistoryFieldDiffDto>[];

    final allIdentityKeys = <String>{
      ...current.customFields.map((e) => e.identityKey),
      ...replacement.customFields.map((e) => e.identityKey),
    };

    for (final identityKey in allIdentityKeys) {
      final oldF = current.customFields.firstWhereOrNull(
        (e) => e.identityKey == identityKey,
      );
      final newF = replacement.customFields.firstWhereOrNull(
        (e) => e.identityKey == identityKey,
      );

      if (oldF == null && newF == null) continue;

      final oldVal = oldF?.value;
      final newVal = newF?.value;

      if (oldF != null && newF != null && oldVal == newVal) {
        continue;
      }

      final label = newF?.label ?? oldF?.label ?? identityKey;
      final isSensitive =
          (oldF?.isSensitive ?? false) || (newF?.isSensitive ?? false);

      diffs.add(
        VaultHistoryFieldDiffDto(
          fieldKey: identityKey,
          label: label,
          oldValue: isSensitive ? '••••••' : oldVal,
          newValue: isSensitive ? '••••••' : newVal,
          changeType: _determineChangeType(oldVal, newVal),
          isSensitive: isSensitive,
        ),
      );
    }

    return diffs;
  }

  HistoryFieldChangeType _determineChangeType(Object? oldVal, Object? newVal) {
    if (oldVal == null && newVal != null) return HistoryFieldChangeType.added;
    if (oldVal != null && newVal == null) return HistoryFieldChangeType.removed;
    return HistoryFieldChangeType.changed;
  }
}
