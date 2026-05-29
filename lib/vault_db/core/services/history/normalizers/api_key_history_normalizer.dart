import 'package:hoplixi/vault_db/core/repositories/base/api_key_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
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
  AsyncDbResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await apiKeyHistoryDao.getApiKeyHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          ApiKeyHistoryPayload(
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
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDbResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final viewOpt = (await apiKeyRepository.getViewById(
          itemId,
        )).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.apiKey;
          return Some(
            ApiKeyHistoryPayload(
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
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
