import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class ApiKeySnapshotHandler implements VaultSnapshotTypeHandler {
  ApiKeySnapshotHandler({required this.apiKeyHistoryDao});

  final ApiKeyHistoryDao apiKeyHistoryDao;

  @override
  VaultItemType get type => VaultItemType.apiKey;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! ApiKeyViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for ApiKey snapshot',
            entity: 'apiKey',
          );
        }

        final apiKey = view.apiKey;

        await apiKeyHistoryDao.insertApiKeyHistory(
          ApiKeyHistoryCompanion.insert(
            historyId: historyId,
            service: apiKey.service,
            key: Value(includeSecrets ? apiKey.key : null),
            tokenType: Value(apiKey.tokenType),
            tokenTypeOther: Value(apiKey.tokenTypeOther),
            environment: Value(apiKey.environment),
            environmentOther: Value(apiKey.environmentOther),
            expiresAt: Value(apiKey.expiresAt),
            revokedAt: Value(apiKey.revokedAt),
            rotationPeriodDays: Value(apiKey.rotationPeriodDays),
            lastRotatedAt: Value(apiKey.lastRotatedAt),
            owner: Value(apiKey.owner),
            baseUrl: Value(apiKey.baseUrl),
            scopesText: Value(apiKey.scopesText),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
