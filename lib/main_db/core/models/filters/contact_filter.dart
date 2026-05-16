import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'contact_filter.freezed.dart';
part 'contact_filter.g.dart';

enum ContactSortField {
  name,
  firstName,
  lastName,
  company,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class ContactFilter with _$ContactFilter {
  const factory ContactFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? website,

    DateTime? birthdayAfter,
    DateTime? birthdayBefore,

    bool? isEmergencyContact,

    ContactSortField? sortField,
  }) = _ContactFilter;

  factory ContactFilter.create({
    BaseFilter? base,
    String? phone,
    String? email,
    String? company,
    String? jobTitle,
    String? website,
    DateTime? birthdayAfter,
    DateTime? birthdayBefore,
    bool? isEmergencyContact,
    ContactSortField? sortField,
  }) {
    final normalizedPhone = phone?.trim();
    final normalizedEmail = email?.trim();
    final normalizedCompany = company?.trim();
    final normalizedJobTitle = jobTitle?.trim();
    final normalizedWebsite = website?.trim();

    return ContactFilter(
      base: base ?? const BaseFilter(),
      phone: normalizedPhone?.isEmpty == true ? null : normalizedPhone,
      email: normalizedEmail?.isEmpty == true ? null : normalizedEmail,
      company: normalizedCompany?.isEmpty == true ? null : normalizedCompany,
      jobTitle: normalizedJobTitle?.isEmpty == true ? null : normalizedJobTitle,
      website: normalizedWebsite?.isEmpty == true ? null : normalizedWebsite,
      birthdayAfter: birthdayAfter,
      birthdayBefore: birthdayBefore,
      isEmergencyContact: isEmergencyContact,
      sortField: sortField,
    );
  }

  factory ContactFilter.fromJson(Map<String, dynamic> json) =>
      _$ContactFilterFromJson(json);
}

extension ContactFilterHelpers on ContactFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (phone != null) return true;
    if (email != null) return true;
    if (company != null) return true;
    if (jobTitle != null) return true;
    if (website != null) return true;
    if (birthdayAfter != null || birthdayBefore != null) return true;
    if (isEmergencyContact != null) return true;
    return false;
  }
}
