import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/api_key_history_payload.dart';
import 'vault_history_restore_handler.dart';

class ApiKeyHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  ApiKeyHistoryRestoreHandler({required this.apiKeyItemsDao});

  final ApiKeyItemsDao apiKeyItemsDao;

  @override
  VaultItemType get type => VaultItemType.apiKey;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! ApiKeyHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for ApiKey restore',
          entity: 'apiKey',
        ),
      );
    }

    if (payload.key == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message: 'Нельзя восстановить API Key: отсутствует ключ',
          entity: 'apiKey',
        ),
      );
    }

    await apiKeyItemsDao.upsertApiKeyItem(
      ApiKeyItemsCompanion(
        itemId: Value(base.itemId),
        service: Value(payload.service),
        key: Value(payload.key!),
        tokenType: Value(payload.tokenType),
        tokenTypeOther: Value(payload.tokenTypeOther),
        environment: Value(payload.environment),
        environmentOther: Value(payload.environmentOther),
        expiresAt: Value(payload.expiresAt),
        revokedAt: Value(payload.revokedAt),
        rotationPeriodDays: Value(payload.rotationPeriodDays),
        lastRotatedAt: Value(payload.lastRotatedAt),
        owner: Value(payload.owner),
        baseUrl: Value(payload.baseUrl),
        scopesText: Value(payload.scopesText),
      ),
    );

    return const Success(unit);
  }
}
