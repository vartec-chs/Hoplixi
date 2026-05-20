import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/wifi/wifi_items.dart';
import 'base_filter.dart';

part 'wifi_filter.freezed.dart';
part 'wifi_filter.g.dart';

enum WifiSortField {
  name,
  ssid,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class WifiFilter with _$WifiFilter {
  const factory WifiFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? ssid,
    WifiSecurityType? securityType,
    WifiEncryptionType? encryption,
    bool? hiddenSsid,
    bool? hasPassword,

    WifiSortField? sortField,
  }) = _WifiFilter;

  factory WifiFilter.create({
    BaseFilter? base,
    String? ssid,
    WifiSecurityType? securityType,
    WifiEncryptionType? encryption,
    bool? hiddenSsid,
    bool? hasPassword,
    WifiSortField? sortField,
  }) {
    final normalizedSsid = ssid?.trim();

    return WifiFilter(
      base: base ?? const BaseFilter(),
      ssid: normalizedSsid?.isEmpty == true ? null : normalizedSsid,
      securityType: securityType,
      encryption: encryption,
      hiddenSsid: hiddenSsid,
      hasPassword: hasPassword,
      sortField: sortField,
    );
  }

  factory WifiFilter.fromJson(Map<String, dynamic> json) =>
      _$WifiFilterFromJson(json);
}

extension WifiFilterHelpers on WifiFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (ssid != null) return true;
    if (securityType != null) return true;
    if (encryption != null) return true;
    if (hiddenSsid != null) return true;
    if (hasPassword != null) return true;
    return false;
  }
}
