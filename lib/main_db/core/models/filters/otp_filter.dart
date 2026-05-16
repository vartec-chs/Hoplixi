import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/otp/otp_items.dart';
import 'base_filter.dart';

part 'otp_filter.freezed.dart';
part 'otp_filter.g.dart';

enum OtpSortField {
  name,
  issuer,
  accountName,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class OtpFilter with _$OtpFilter {
  const factory OtpFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? issuer,
    String? accountName,
    OtpType? type,
    OtpHashAlgorithm? algorithm,
    int? digits,

    bool? hasIssuer,
    bool? hasAccountName,

    OtpSortField? sortField,
  }) = _OtpFilter;

  factory OtpFilter.create({
    BaseFilter? base,
    String? issuer,
    String? accountName,
    OtpType? type,
    OtpHashAlgorithm? algorithm,
    int? digits,
    bool? hasIssuer,
    bool? hasAccountName,
    OtpSortField? sortField,
  }) {
    final normalizedIssuer = issuer?.trim();
    final normalizedAccountName = accountName?.trim();

    return OtpFilter(
      base: base ?? const BaseFilter(),
      issuer: normalizedIssuer?.isEmpty == true ? null : normalizedIssuer,
      accountName: normalizedAccountName?.isEmpty == true ? null : normalizedAccountName,
      type: type,
      algorithm: algorithm,
      digits: digits,
      hasIssuer: hasIssuer,
      hasAccountName: hasAccountName,
      sortField: sortField,
    );
  }

  factory OtpFilter.fromJson(Map<String, dynamic> json) =>
      _$OtpFilterFromJson(json);
}

extension OtpFilterHelpers on OtpFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (issuer != null) return true;
    if (accountName != null) return true;
    if (type != null) return true;
    if (algorithm != null) return true;
    if (digits != null) return true;
    if (hasIssuer != null) return true;
    if (hasAccountName != null) return true;
    return false;
  }
}
