import 'package:hoplixi/main_db/core/repositories/base/api_key_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/api_key_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class ApiKeyHistoryNormalizer implements VaultHistoryTypeNormalizer {
  ApiKeyHistoryNormalizer({
    required this.apiKeyHistoryDao,
    required this.apiKeyRepository,
  });

  final ApiKeyHistoryDao apiKeyHistoryDao;
  final ApiKeyRepository apiKeyRepository;

  @override
  VaultItemType get type => VaultItemType.apiKey;

  @override
  Future<HistoryPayload?> normalizeHistory({required String historyId}) async {
    final rows = await apiKeyHistoryDao.getApiKeyHistoryByHistoryIds([
      historyId,
    ]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return ApiKeyHistoryPayload(
      service: item.service,
      key: item.key,
      tokenType: item.tokenType,
      tokenTypeOther: item.tokenTypeOther,
      environment: item.environment,
      environmentOther: item.environmentOther,
      expiresAt: item.expiresAt,
      revokedAt: item.revokedAt,
      rotationPeriodDays: item.rotationPeriodDays,
      lastRotatedAt: item.lastRotatedAt,
      owner: item.owner,
      baseUrl: item.baseUrl,
      scopesText: item.scopesText,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({required String itemId}) async {
    final view = await apiKeyRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.apiKey;

    return ApiKeyHistoryPayload(
      service: item.service,
      key: item.key,
      tokenType: item.tokenType,
      tokenTypeOther: item.tokenTypeOther,
      environment: item.environment,
      environmentOther: item.environmentOther,
      expiresAt: item.expiresAt,
      revokedAt: item.revokedAt,
      rotationPeriodDays: item.rotationPeriodDays,
      lastRotatedAt: item.lastRotatedAt,
      owner: item.owner,
      baseUrl: item.baseUrl,
      scopesText: item.scopesText,
    );
  }
}
