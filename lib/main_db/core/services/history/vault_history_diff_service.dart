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
    // TODO: Implement custom field diffing
    return const [];
  }

  HistoryFieldChangeType _determineChangeType(Object? oldVal, Object? newVal) {
    if (oldVal == null && newVal != null) return HistoryFieldChangeType.added;
    if (oldVal != null && newVal == null) return HistoryFieldChangeType.removed;
    return HistoryFieldChangeType.changed;
  }
}
