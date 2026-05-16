import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../tables/api_key/api_key_items.dart';
import 'base_filter.dart';

part 'api_key_filter.freezed.dart';
part 'api_key_filter.g.dart';

enum ApiKeySortField {
  name,
  service,
  tokenType,
  environment,
  expiresAt,
  revokedAt,
  createdAt,
  modifiedAt,
  lastUsedAt,
  usedCount,
  recentScore,
}

@freezed
sealed class ApiKeyFilter with _$ApiKeyFilter {
  const factory ApiKeyFilter({
    @Default(BaseFilter()) BaseFilter base,

    String? name,
    String? service,
    ApiKeyTokenType? tokenType,
    ApiKeyEnvironment? environment,

    bool? isRevoked,
    bool? hasExpiration,
    bool? hasOwner,
    bool? hasBaseUrl,
    bool? hasScopes,

    ApiKeySortField? sortField,
  }) = _ApiKeyFilter;

  factory ApiKeyFilter.create({
    BaseFilter? base,
    String? name,
    String? service,
    ApiKeyTokenType? tokenType,
    ApiKeyEnvironment? environment,
    bool? isRevoked,
    bool? hasExpiration,
    bool? hasOwner,
    bool? hasBaseUrl,
    bool? hasScopes,
    ApiKeySortField? sortField,
  }) {
    final normalizedName = name?.trim();
    final normalizedService = service?.trim();

    return ApiKeyFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      service: normalizedService?.isEmpty == true ? null : normalizedService,
      tokenType: tokenType,
      environment: environment,
      isRevoked: isRevoked,
      hasExpiration: hasExpiration,
      hasOwner: hasOwner,
      hasBaseUrl: hasBaseUrl,
      hasScopes: hasScopes,
      sortField: sortField,
    );
  }

  factory ApiKeyFilter.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyFilterFromJson(json);
}

extension ApiKeyFilterHelpers on ApiKeyFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (service != null) return true;
    if (tokenType != null) return true;
    if (environment != null) return true;
    if (isRevoked != null) return true;
    if (hasExpiration != null) return true;
    if (hasOwner != null) return true;
    if (hasBaseUrl != null) return true;
    if (hasScopes != null) return true;
    return false;
  }
}
