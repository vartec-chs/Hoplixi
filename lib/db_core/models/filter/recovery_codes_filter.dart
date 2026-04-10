import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'recovery_codes_filter.freezed.dart';
part 'recovery_codes_filter.g.dart';

enum RecoveryCodesSortField {
  name,
  codesCount,
  usedCount,
  generatedAt,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class RecoveryCodesFilter with _$RecoveryCodesFilter {
  const factory RecoveryCodesFilter({
    required BaseFilter base,
    String? name,
    String? displayHint,
    bool? oneTime,
    bool? depletedOnly,
    RecoveryCodesSortField? sortField,
  }) = _RecoveryCodesFilter;

  factory RecoveryCodesFilter.create({
    BaseFilter? base,
    String? name,
    String? displayHint,
    bool? oneTime,
    bool? depletedOnly,
    RecoveryCodesSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return RecoveryCodesFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      displayHint: normalize(displayHint),
      oneTime: oneTime,
      depletedOnly: depletedOnly,
      sortField: sortField,
    );
  }

  factory RecoveryCodesFilter.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesFilterFromJson(json);
}

extension RecoveryCodesFilterHelpers on RecoveryCodesFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (displayHint != null) return true;
    if (oneTime != null) return true;
    if (depletedOnly != null) return true;
    return false;
  }
}
