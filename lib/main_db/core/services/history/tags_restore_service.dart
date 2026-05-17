import 'package:result_dart/result_dart.dart';
import '../../daos/daos.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';

class TagsRestoreResult {
  const TagsRestoreResult({
    required this.restoredCount,
    required this.skippedMissingTagIds,
  });

  final int restoredCount;
  final List<String> skippedMissingTagIds;
}

class TagsRestoreService {
  TagsRestoreService({
    required this.itemTagsDao,
    required this.vaultItemTagHistoryDao,
    required this.tagsDao,
  });

  final ItemTagsDao itemTagsDao;
  final VaultItemTagHistoryDao vaultItemTagHistoryDao;
  final TagsDao tagsDao;

  Future<DbResult<TagsRestoreResult>> restoreTagsForSnapshot({
    required String itemId,
    required String snapshotHistoryId,
  }) async {
    try {
      final tagHistoryList = await vaultItemTagHistoryDao
          .getTagsBySnapshotHistoryId(snapshotHistoryId);

      await itemTagsDao.removeAllTagsFromItem(itemId);

      int restoredCount = 0;
      final skippedMissingTagIds = <String>[];

      for (final tagHistory in tagHistoryList) {
        final tagId = tagHistory.tagId;
        if (tagId == null) {
          continue; // Missing original ID
        }

        final exists = await tagsDao.existsTag(tagId);
        if (exists) {
          await itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          restoredCount++;
        } else {
          skippedMissingTagIds.add(tagId);
        }
      }

      return Success(
        TagsRestoreResult(
          restoredCount: restoredCount,
          skippedMissingTagIds: skippedMissingTagIds,
        ),
      );
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
