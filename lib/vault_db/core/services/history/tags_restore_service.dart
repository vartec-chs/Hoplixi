import 'dart:convert';
import 'package:hoplixi/vault_db/core/models/dto_history/vault_item_tags_snapshot_dto.dart';
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
    required this.vaultSnapshotsHistoryDao,
    required this.tagsDao,
  });

  final ItemTagsDao itemTagsDao;
  final VaultSnapshotsHistoryDao vaultSnapshotsHistoryDao;
  final TagsDao tagsDao;

  Future<DBResult<TagsRestoreResult>> restoreTagsForSnapshot({
    required String itemId,
    required String snapshotHistoryId,
  }) async {
    try {
      final snapshot = await vaultSnapshotsHistoryDao.getSnapshotById(
        snapshotHistoryId,
      );

      await itemTagsDao.removeAllTagsFromItem(itemId);

      int restoredCount = 0;
      final skippedMissingTagIds = <String>[];

      if (snapshot != null && snapshot.tagsSnapshotJson != null) {
        final tagsSnapshot = VaultItemTagsSnapshotDto.fromJson(
          jsonDecode(snapshot.tagsSnapshotJson!) as Map<String, dynamic>,
        );
        for (final tagItem in tagsSnapshot.tags) {
          final tagName = tagItem.name;

          final tag = await tagsDao.getTagByName(tagName);
          if (tag != null) {
            await itemTagsDao.assignTagToItem(itemId: itemId, tagId: tag.id);
            restoredCount++;
          } else {
            skippedMissingTagIds.add(tagName);
          }
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
