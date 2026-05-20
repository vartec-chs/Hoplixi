import 'package:hoplixi/vault_db/core/models/dto/api_key_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension ApiKeyItemsDataMapper on ApiKeyItemsData {
  ApiKeyDataDto toApiKeyDataDto() {
    return ApiKeyDataDto(
      service: service,
      key: key,
      tokenType: tokenType,
      tokenTypeOther: tokenTypeOther,
      environment: environment,
      environmentOther: environmentOther,
      expiresAt: expiresAt,
      revokedAt: revokedAt,
      rotationPeriodDays: rotationPeriodDays,
      lastRotatedAt: lastRotatedAt,
      owner: owner,
      baseUrl: baseUrl,
      scopesText: scopesText,
    );
  }

  ApiKeyCardDataDto toApiKeyCardDataDto() {
    return ApiKeyCardDataDto(
      service: service,
      tokenType: tokenType,
      environment: environment,
      expiresAt: expiresAt,
      revokedAt: revokedAt,
      rotationPeriodDays: rotationPeriodDays,
      lastRotatedAt: lastRotatedAt,
      owner: owner,
      baseUrl: baseUrl,
      hasKey: key.isNotEmpty,
    );
  }
}
