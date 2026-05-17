import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'identity_filter.freezed.dart';
part 'identity_filter.g.dart';

enum IdentitySortField {
  name,
  displayName,
  username,
  email,
  company,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class IdentityFilter with _$IdentityFilter {
  const factory IdentityFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? firstName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? website,

    bool? hasTaxId,
    bool? hasNationalId,
    bool? hasPassportNumber,
    bool? hasDriverLicenseNumber,

    IdentitySortField? sortField,
  }) = _IdentityFilter;

  factory IdentityFilter.create({
    BaseFilter? base,
    String? firstName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? company,
    String? jobTitle,
    String? website,
    bool? hasTaxId,
    bool? hasNationalId,
    bool? hasPassportNumber,
    bool? hasDriverLicenseNumber,
    IdentitySortField? sortField,
  }) {
    final normalizedFirstName = firstName?.trim();
    final normalizedLastName = lastName?.trim();
    final normalizedDisplayName = displayName?.trim();
    final normalizedUsername = username?.trim();
    final normalizedEmail = email?.trim();
    final normalizedPhone = phone?.trim();
    final normalizedCompany = company?.trim();
    final normalizedJobTitle = jobTitle?.trim();
    final normalizedWebsite = website?.trim();

    return IdentityFilter(
      base: base ?? const BaseFilter(),
      firstName: normalizedFirstName?.isEmpty == true
          ? null
          : normalizedFirstName,
      lastName: normalizedLastName?.isEmpty == true ? null : normalizedLastName,
      displayName: normalizedDisplayName?.isEmpty == true
          ? null
          : normalizedDisplayName,
      username: normalizedUsername?.isEmpty == true ? null : normalizedUsername,
      email: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
      phone: normalizedPhone?.isEmpty == true ? null : normalizedPhone,
      company: normalizedCompany?.isEmpty == true ? null : normalizedCompany,
      jobTitle: normalizedJobTitle?.isEmpty == true ? null : normalizedJobTitle,
      website: normalizedWebsite?.isEmpty == true ? null : normalizedWebsite,
      hasTaxId: hasTaxId,
      hasNationalId: hasNationalId,
      hasPassportNumber: hasPassportNumber,
      hasDriverLicenseNumber: hasDriverLicenseNumber,
      sortField: sortField,
    );
  }

  factory IdentityFilter.fromJson(Map<String, dynamic> json) =>
      _$IdentityFilterFromJson(json);
}

extension IdentityFilterHelpers on IdentityFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (firstName != null) return true;
    if (lastName != null) return true;
    if (displayName != null) return true;
    if (username != null) return true;
    if (email != null) return true;
    if (phone != null) return true;
    if (company != null) return true;
    if (jobTitle != null) return true;
    if (website != null) return true;
    if (hasTaxId != null) return true;
    if (hasNationalId != null) return true;
    if (hasPassportNumber != null) return true;
    if (hasDriverLicenseNumber != null) return true;
    return false;
  }
}
