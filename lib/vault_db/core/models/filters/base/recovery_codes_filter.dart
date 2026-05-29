import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'recovery_codes_filter.freezed.dart';
part 'recovery_codes_filter.g.dart';

enum RecoveryCodesSortField {
  name,
  generatedAt,
  createdAt,
  modifiedAt,
  lastUsedAt,
  recentScore,
}

@freezed
sealed class RecoveryCodesFilter with _$RecoveryCodesFilter {
  const factory RecoveryCodesFilter({
    @Default(BaseFilter()) BaseFilter base,

    DateTime? generatedAfter,
    DateTime? generatedBefore,

    bool? oneTime,

    bool? hasCodes,

    RecoveryCodesSortField? sortField,
  }) = _RecoveryCodesFilter;

  factory RecoveryCodesFilter.create({
    BaseFilter? base,
    DateTime? generatedAfter,
    DateTime? generatedBefore,
    bool? oneTime,
    bool? hasCodes,
    RecoveryCodesSortField? sortField,
  }) {
    return RecoveryCodesFilter(
      base: base ?? const BaseFilter(),
      generatedAfter: generatedAfter,
      generatedBefore: generatedBefore,
      oneTime: oneTime,
      hasCodes: hasCodes,
      sortField: sortField,
    );
  }

  factory RecoveryCodesFilter.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesFilterFromJson(json);
}

extension RecoveryCodesFilterHelpers on RecoveryCodesFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (generatedAfter != null || generatedBefore != null) return true;
    if (oneTime != null) return true;
    if (hasCodes != null) return true;
    return false;
  }
}
