import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'wifis_filter.freezed.dart';
part 'wifis_filter.g.dart';

enum WifisSortField {
  name,
  ssid,
  priority,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class WifisFilter with _$WifisFilter {
  const factory WifisFilter({
    required BaseFilter base,
    String? name,
    String? ssid,
    String? security,
    String? eapMethod,
    bool? hidden,
    bool? hasPassword,
    bool? isOpenNetwork,
    WifisSortField? sortField,
  }) = _WifisFilter;

  factory WifisFilter.create({
    BaseFilter? base,
    String? name,
    String? ssid,
    String? security,
    String? eapMethod,
    bool? hidden,
    bool? hasPassword,
    bool? isOpenNetwork,
    WifisSortField? sortField,
  }) {
    String? normalize(String? value) {
      final result = value?.trim();
      if (result == null || result.isEmpty) return null;
      return result;
    }

    return WifisFilter(
      base: base ?? const BaseFilter(),
      name: normalize(name),
      ssid: normalize(ssid),
      security: normalize(security),
      eapMethod: normalize(eapMethod),
      hidden: hidden,
      hasPassword: hasPassword,
      isOpenNetwork: isOpenNetwork,
      sortField: sortField,
    );
  }

  factory WifisFilter.fromJson(Map<String, dynamic> json) =>
      _$WifisFilterFromJson(json);
}

extension WifisFilterHelpers on WifisFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (ssid != null) return true;
    if (security != null) return true;
    if (eapMethod != null) return true;
    if (hidden != null) return true;
    if (hasPassword != null) return true;
    if (isOpenNetwork != null) return true;
    return false;
  }
}
