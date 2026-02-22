import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'contacts_filter.freezed.dart';
part 'contacts_filter.g.dart';

enum ContactsSortField { name, company, createdAt, modifiedAt, lastAccessed }

@freezed
abstract class ContactsFilter with _$ContactsFilter {
  const factory ContactsFilter({
    required BaseFilter base,
    String? name,
    String? phone,
    String? email,
    String? company,
    bool? isEmergencyContact,
    bool? hasPhone,
    bool? hasEmail,
    ContactsSortField? sortField,
  }) = _ContactsFilter;

  factory ContactsFilter.create({
    BaseFilter? base,
    String? name,
    String? phone,
    String? email,
    String? company,
    bool? isEmergencyContact,
    bool? hasPhone,
    bool? hasEmail,
    ContactsSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return ContactsFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      phone: normalize(phone),
      email: normalize(email),
      company: normalize(company),
      isEmergencyContact: isEmergencyContact,
      hasPhone: hasPhone,
      hasEmail: hasEmail,
      sortField: sortField,
    );
  }

  factory ContactsFilter.fromJson(Map<String, dynamic> json) =>
      _$ContactsFilterFromJson(json);
}

extension ContactsFilterHelpers on ContactsFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (phone != null) return true;
    if (email != null) return true;
    if (company != null) return true;
    if (isEmergencyContact != null) return true;
    if (hasPhone != null) return true;
    if (hasEmail != null) return true;
    return false;
  }
}
