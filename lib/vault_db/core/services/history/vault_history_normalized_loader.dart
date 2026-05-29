import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/services/history/history.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

import '../../daos/daos.dart';
import '../../models/mappers/history/vault_item_base_history_payload_mapper.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class VaultHistoryNormalizedLoader {
  VaultHistoryNormalizedLoader({
    required this.db,
    required this.restorePolicyService,
    required this.historyModules,
  }) : snapshotsHistoryDao = db.vaultSnapshotsHistoryDao,
       vaultItemsDao = db.vaultItemsDao,
       customFieldsHistoryDao = db.vaultItemCustomFieldsHistoryDao,
       customFieldsDao = db.vaultItemCustomFieldsDao;

  final VaultDB db;

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultItemsDao vaultItemsDao;
  final VaultHistoryRestorePolicyService restorePolicyService;
  final VaultItemHistoryModules historyModules;
  final VaultItemCustomFieldsHistoryDao customFieldsHistoryDao;
  final VaultItemCustomFieldsDao customFieldsDao;

  AsyncDbResult<Optional<AnyNormalizedHistorySnapshot>> loadHistorySnapshot(
    String historyId,
  ) {
    return tryCatchAsync(
      () async {
        final snapshotData = await snapshotsHistoryDao.getSnapshotById(
          historyId,
        );
        if (snapshotData == null) return const None();

        final base = snapshotData.toVaultItemBaseHistoryPayload();

        final normalizer = historyModules.normalizer(base.type);
        HistoryPayload? payload;

        if (normalizer != null) {
          final payloadResult = await normalizer.normalizeHistory(
            historyId: historyId,
          );
          payload = payloadResult.getOrThrow().getOrNull();
        }

        payload ??= EmptyHistoryPayload(base.type);

        final customFields = await _loadHistoryCustomFields(historyId);

        final normalized = NormalizedHistorySnapshot(
          base: base,
          payload: payload,
          customFields: customFields,
          restoreWarnings: const [],
        );

        return Some(
          normalized.copyWith(
            restoreWarnings: restorePolicyService.restoreWarnings(normalized),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при загрузке снимка истории',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<AnyNormalizedHistorySnapshot>> loadCurrentSnapshot({
    required String itemId,
    required VaultItemType type,
  }) {
    return tryCatchAsync(
      () async {
        final itemData = await vaultItemsDao.getVaultItemById(itemId);
        if (itemData == null) return const None();

        final base = itemData.toCurrentVaultItemBaseHistoryPayload();

        final normalizer = historyModules.normalizer(base.type);
        HistoryPayload? payload;

        if (normalizer != null) {
          final payloadResult = await normalizer.normalizeCurrent(
            itemId: itemId,
          );
          payload = payloadResult.getOrThrow().getOrNull();
        }

        payload ??= EmptyHistoryPayload(base.type);

        final customFields = await _loadCurrentCustomFields(itemId);

        final normalized = NormalizedHistorySnapshot(
          base: base,
          payload: payload,
          customFields: customFields,
          restoreWarnings: const [],
        );

        return Some(
          normalized.copyWith(
            restoreWarnings: restorePolicyService.restoreWarnings(normalized),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при загрузке текущего состояния элемента',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  Future<List<NormalizedCustomField>> _loadHistoryCustomFields(
    String historyId,
  ) async {
    final rows = await customFieldsHistoryDao
        .getCustomFieldsHistoryBySnapshotHistoryId(historyId);

    return rows
        .map(
          (r) => NormalizedCustomField(
            identityKey: r.originalFieldId ?? r.id,
            originalFieldId: r.originalFieldId,
            label: r.label,
            value: r.value,
            fieldType: r.fieldType,
            isSecret: r.isSecret,
            sortOrder: r.sortOrder,
          ),
        )
        .toList();
  }

  Future<List<NormalizedCustomField>> _loadCurrentCustomFields(
    String itemId,
  ) async {
    final rows = await customFieldsDao.getCustomFieldsByItemId(itemId);

    return rows
        .map(
          (r) => NormalizedCustomField(
            identityKey: r.id,
            originalFieldId: r.id,
            label: r.label,
            value: r.value,
            fieldType: r.fieldType,
            isSecret: r.isSecret,
            sortOrder: r.sortOrder,
          ),
        )
        .toList();
  }
}
