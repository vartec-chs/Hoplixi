import 'package:result_dart/result_dart.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';
import '../../daos/daos.dart';
import 'vault_history_normalized_loader.dart';
import 'vault_history_restore_policy_service.dart';
import '../../tables/vault_items/vault_items.dart';
import '../../main_store.dart';
import '../../tables/api_key/api_key_items.dart';
import 'package:drift/drift.dart';

class VaultHistoryRestoreService {
  VaultHistoryRestoreService({
    required this.loader,
    required this.policy,
    required this.db,
    required this.vaultItemsDao,
    required this.apiKeyItemsDao,
  });

  final VaultHistoryNormalizedLoader loader;
  final VaultHistoryRestorePolicyService policy;
  final MainStore db;
  final VaultItemsDao vaultItemsDao;
  final ApiKeyItemsDao apiKeyItemsDao;

  Future<DbResult<Unit>> restoreRevision({
    required String historyId,
    bool recreate = false,
  }) async {
    try {
      final selected = await loader.loadHistorySnapshot(historyId);
      if (selected == null) {
        return Failure(DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId));
      }

      if (!policy.isRestorable(selected)) {
        return Failure(DBCoreError.validation(
          code: 'restore_not_allowed',
          message: 'Restore is not allowed for this item type or state.',
          entity: selected.snapshot.type.name,
        ));
      }

      return await db.transaction(() async {
        final snapshot = selected.snapshot;

        // 1. Restore base vault item
        await vaultItemsDao.upsertVaultItem(VaultItemsCompanion(
          id: Value(snapshot.itemId),
          type: Value(snapshot.type),
          name: Value(snapshot.name),
          description: Value(snapshot.description),
          categoryId: Value(snapshot.categoryId),
          iconRefId: Value(snapshot.iconRefId),
          isFavorite: Value(snapshot.isFavorite),
          isArchived: Value(snapshot.isArchived),
          isPinned: Value(snapshot.isPinned),
          isDeleted: Value(snapshot.isDeleted),
          createdAt: Value(snapshot.createdAt),
          modifiedAt: Value(DateTime.now()),
        ));

        // 2. Restore type-specific data
        switch (snapshot.type) {
          case VaultItemType.apiKey:
            final fields = selected.fields;
            await apiKeyItemsDao.upsertApiKeyItem(ApiKeyItemsCompanion(
              itemId: Value(snapshot.itemId),
              service: Value(fields['service'] as String),
              key: Value(fields['key'] as String),
              tokenType: Value(fields['tokenType'] != null ? ApiKeyTokenType.values.byName(fields['tokenType'] as String) : null),
              environment: Value(fields['environment'] != null ? ApiKeyEnvironment.values.byName(fields['environment'] as String) : null),
              expiresAt: Value(fields['expiresAt'] as DateTime?),
              owner: Value(fields['owner'] as String?),
              baseUrl: Value(fields['baseUrl'] as String?),
            ));
            break;
          // Stage 1: Others TODO
          default:
            throw UnimplementedError('Restore for ${snapshot.type} not implemented in Stage 1');
        }

        return Success(unit);
      });
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }
}
