import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../daos/daos.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';

class ItemLinksRestoreResult {
  const ItemLinksRestoreResult({
    required this.restoredCount,
    required this.skippedMissingItemIds,
    required this.skippedSelfLinksCount,
  });

  final int restoredCount;
  final List<String> skippedMissingItemIds;
  final int skippedSelfLinksCount;
}

class ItemLinksRestoreService {
  ItemLinksRestoreService({
    required this.itemLinksDao,
    required this.itemLinkHistoryDao,
    required this.vaultItemsDao,
  });

  final ItemLinksDao itemLinksDao;
  final ItemLinkHistoryDao itemLinkHistoryDao;
  final VaultItemsDao vaultItemsDao;

  Future<DbResult<ItemLinksRestoreResult>> restoreLinksForSnapshot({
    required String itemId,
    required String snapshotHistoryId,
  }) async {
    try {
      final historyLinks = await itemLinkHistoryDao.getLinksBySnapshotHistoryId(snapshotHistoryId);
      
      await itemLinksDao.deleteLinksForItem(itemId);

      int restoredCount = 0;
      final skippedMissingItemIds = <String>[];
      int skippedSelfLinksCount = 0;

      for (final h in historyLinks) {
        if (h.sourceItemId == h.targetItemId) {
          skippedSelfLinksCount++;
          continue;
        }

        final sourceExists = await vaultItemsDao.existsVaultItem(h.sourceItemId);
        final targetExists = await vaultItemsDao.existsVaultItem(h.targetItemId);


        if (!sourceExists) {
          skippedMissingItemIds.add(h.sourceItemId);
          continue;
        }
        if (!targetExists) {
          skippedMissingItemIds.add(h.targetItemId);
          continue;
        }

        await itemLinksDao.insertRestoredLink(ItemLinksCompanion(
          id: Value(h.sourceLinkId ?? const Uuid().v4()),
          sourceItemId: Value(h.sourceItemId),
          targetItemId: Value(h.targetItemId),
          relationType: Value(h.relationType),
          relationTypeOther: Value(h.relationTypeOther),
          label: Value(h.label),
          sortOrder: Value(h.sortOrder),
          createdAt: Value(h.createdAt),
          modifiedAt: Value(h.modifiedAt),
        ));

        
        restoredCount++;
      }

      return Success(ItemLinksRestoreResult(
        restoredCount: restoredCount,
        skippedMissingItemIds: skippedMissingItemIds.toSet().toList(),
        skippedSelfLinksCount: skippedSelfLinksCount,
      ));
    } catch (e, s) {
      return Failure(DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s));
    }
  }
}
