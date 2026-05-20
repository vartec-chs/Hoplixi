import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'password_filter.freezed.dart';
part 'password_filter.g.dart';

enum PasswordSortField {
  name,
  login,
  email,
  url,
  expiresAt,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class PasswordFilter with _$PasswordFilter {
  const factory PasswordFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? name,
    String? login,
    String? email,
    String? url,

    bool? hasLogin,
    bool? hasEmail,
    bool? hasUrl,
    bool? hasPassword,

    PasswordSortField? sortField,
  }) = _PasswordFilter;

  factory PasswordFilter.create({
    BaseFilter? base,
    String? name,
    String? login,
    String? email,
    String? url,
    bool? hasLogin,
    bool? hasEmail,
    bool? hasUrl,
    bool? hasPassword,
    PasswordSortField? sortField,
  }) {
    final normalizedName = name?.trim();
    final normalizedLogin = login?.trim();
    final normalizedEmail = email?.trim();
    final normalizedUrl = url?.trim();

    return PasswordFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      login: normalizedLogin?.isEmpty == true ? null : normalizedLogin,
      email: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
      url: normalizedUrl?.isEmpty == true ? null : normalizedUrl,
      hasLogin: hasLogin,
      hasEmail: hasEmail,
      hasUrl: hasUrl,
      hasPassword: hasPassword,
      sortField: sortField,
    );
  }

  factory PasswordFilter.fromJson(Map<String, dynamic> json) =>
      _$PasswordFilterFromJson(json);
}

extension PasswordFilterHelpers on PasswordFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (login != null) return true;
    if (email != null) return true;
    if (url != null) return true;
    if (hasLogin != null) return true;
    if (hasEmail != null) return true;
    if (hasUrl != null) return true;
    if (hasPassword != null) return true;
    return false;
  }
}
