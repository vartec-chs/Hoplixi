import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_filter.dart';

part 'api_keys_filter.freezed.dart';
part 'api_keys_filter.g.dart';

enum ApiKeysSortField {
  name,
  service,
  environment,
  expiresAt,
  createdAt,
  modifiedAt,
  lastAccessed,
}

@freezed
abstract class ApiKeysFilter with _$ApiKeysFilter {
  const factory ApiKeysFilter({
    required BaseFilter base,
    String? name,
    String? service,
    String? tokenType,
    String? environment,
    bool? revoked,
    bool? hasExpiration,
    ApiKeysSortField? sortField,
  }) = _ApiKeysFilter;

  factory ApiKeysFilter.create({
    BaseFilter? base,
    String? name,
    String? service,
    String? tokenType,
    String? environment,
    bool? revoked,
    bool? hasExpiration,
    ApiKeysSortField? sortField,
  }) {
    final normalizedName = name?.trim();
    final normalizedService = service?.trim();
    final normalizedTokenType = tokenType?.trim();
    final normalizedEnvironment = environment?.trim();

    return ApiKeysFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      service: normalizedService?.isEmpty == true ? null : normalizedService,
      tokenType: normalizedTokenType?.isEmpty == true
          ? null
          : normalizedTokenType,
      environment: normalizedEnvironment?.isEmpty == true
          ? null
          : normalizedEnvironment,
      revoked: revoked,
      hasExpiration: hasExpiration,
      sortField: sortField,
    );
  }

  factory ApiKeysFilter.fromJson(Map<String, dynamic> json) =>
      _$ApiKeysFilterFromJson(json);
}

extension ApiKeysFilterHelpers on ApiKeysFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (service != null) return true;
    if (tokenType != null) return true;
    if (environment != null) return true;
    if (revoked != null) return true;
    if (hasExpiration != null) return true;
    return false;
  }
}
