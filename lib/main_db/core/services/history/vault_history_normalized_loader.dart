import 'package:hoplixi/main_db/core/services/history/history_services.dart';

import '../../daos/daos.dart';
import '../../models/mappers/history/vault_item_base_history_payload_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class VaultHistoryNormalizedLoader {
  VaultHistoryNormalizedLoader({
    required this.snapshotsHistoryDao,
    required this.vaultItemsDao,
    required this.restorePolicyService,
    required this.normalizerRegistry,
    required this.customFieldsHistoryDao,
    required this.customFieldsDao,
  });

  final VaultSnapshotsHistoryDao snapshotsHistoryDao;
  final VaultItemsDao vaultItemsDao;
  final VaultHistoryRestorePolicyService restorePolicyService;
  final VaultHistoryNormalizerRegistry normalizerRegistry;
  final VaultItemCustomFieldsHistoryDao customFieldsHistoryDao;
  final VaultItemCustomFieldsDao customFieldsDao;

  Future<AnyNormalizedHistorySnapshot?> loadHistorySnapshot(
    String historyId,
  ) async {
    final snapshotData = await snapshotsHistoryDao.getSnapshotById(historyId);
    if (snapshotData == null) return null;

    final base = snapshotData.toVaultItemBaseHistoryPayload();

    final normalizer = normalizerRegistry.get(base.type);
    HistoryPayload? payload = await normalizer?.normalizeHistory(
      historyId: historyId,
    );

    payload ??= EmptyHistoryPayload(base.type);

    final customFields = await _loadHistoryCustomFields(historyId);

    final normalized = NormalizedHistorySnapshot(
      base: base,
      payload: payload,
      customFields: customFields,
      restoreWarnings: const [],
    );

    return normalized.copyWith(
      restoreWarnings: restorePolicyService.restoreWarnings(normalized),
    );
  }

  Future<AnyNormalizedHistorySnapshot?> loadCurrentSnapshot({
    required String itemId,
    required VaultItemType type,
  }) async {
    final itemData = await vaultItemsDao.getVaultItemById(itemId);
    if (itemData == null) return null;

    final base = itemData.toCurrentVaultItemBaseHistoryPayload();

    final normalizer = normalizerRegistry.get(base.type);
    HistoryPayload? payload = await normalizer?.normalizeCurrent(
      itemId: itemId,
    );

    payload ??= EmptyHistoryPayload(base.type);

    final customFields = await _loadCurrentCustomFields(itemId);

    final normalized = NormalizedHistorySnapshot(
      base: base,
      payload: payload,
      customFields: customFields,
      restoreWarnings: const [],
    );

    return normalized.copyWith(
      restoreWarnings: restorePolicyService.restoreWarnings(normalized),
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
