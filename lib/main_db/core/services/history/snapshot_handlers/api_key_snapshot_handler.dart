import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class ApiKeySnapshotHandler implements VaultSnapshotTypeHandler {
  ApiKeySnapshotHandler({required this.apiKeyHistoryDao});

  final ApiKeyHistoryDao apiKeyHistoryDao;

  @override
  VaultItemType get type => VaultItemType.apiKey;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! ApiKeyViewDto) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for ApiKey snapshot',
          entity: 'apiKey',
        ),
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

    return const Success(unit);
  }
}
