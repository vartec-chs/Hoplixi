import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'identities_filter.freezed.dart';
part 'identities_filter.g.dart';

enum IdentitiesSortField {
  name,
  idType,
  idNumber,
  expiryDate,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class IdentitiesFilter with _$IdentitiesFilter {
  const factory IdentitiesFilter({
    required BaseFilter base,
    String? name,
    String? idType,
    String? idNumber,
    String? fullName,
    String? nationality,
    bool? verified,
    bool? expiredOnly,
    IdentitiesSortField? sortField,
  }) = _IdentitiesFilter;

  factory IdentitiesFilter.create({
    BaseFilter? base,
    String? name,
    String? idType,
    String? idNumber,
    String? fullName,
    String? nationality,
    bool? verified,
    bool? expiredOnly,
    IdentitiesSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return IdentitiesFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      idType: normalize(idType),
      idNumber: normalize(idNumber),
      fullName: normalize(fullName),
      nationality: normalize(nationality),
      verified: verified,
      expiredOnly: expiredOnly,
      sortField: sortField,
    );
  }

  factory IdentitiesFilter.fromJson(Map<String, dynamic> json) =>
      _$IdentitiesFilterFromJson(json);
}

extension IdentitiesFilterHelpers on IdentitiesFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (idType != null) return true;
    if (idNumber != null) return true;
    if (fullName != null) return true;
    if (nationality != null) return true;
    if (verified != null) return true;
    if (expiredOnly != null) return true;
    return false;
  }
}
