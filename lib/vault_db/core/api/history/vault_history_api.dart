import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto_history/cards/cards_exports.dart';
import 'package:hoplixi/vault_db/core/models/filters/history/vault_snapshot_history_filter.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/services/history/facades/vault_history_timeline_service.dart';
import 'package:hoplixi/vault_db/core/services/history/models/vault_history_timeline_diff_mode.dart';
import 'package:hoplixi/vault_db/core/services/history/vault_history_service_assembly.dart';

/// Public API boundary for vault history read, detail, restore and retention.
class VaultHistoryApi {
  VaultHistoryApi({required VaultHistoryServiceAssembly assembly})
    : _assembly = assembly,
      _timelineService = VaultHistoryTimelineService(
        readService: assembly.readService,
        detailService: assembly.detailService,
        restorePolicyService: assembly.restorePolicy,
      );

  final VaultHistoryServiceAssembly _assembly;
  final VaultHistoryTimelineService _timelineService;

  AsyncDBResult<List<VaultHistoryCardDto>> getCards(
    VaultSnapshotHistoryFilter filter,
  ) {
    return _assembly.readService.getFilteredCards(filter);
  }

  AsyncDBResult<Optional<VaultHistoryCardDto>> getCard(String historyId) {
    return _assembly.readService.getCardByHistoryId(historyId);
  }

  AsyncDBResult<List<VaultHistoryTimelineItemDto>> getTimeline(
    VaultSnapshotHistoryFilter filter, {
    VaultHistoryTimelineDiffMode diffMode =
        VaultHistoryTimelineDiffMode.lightweight,
  }) {
    return _timelineService.getTimeline(filter, diffMode: diffMode);
  }

  AsyncDBResult<VaultHistoryRevisionDetailDto> getRevisionDetail(
    String historyId,
  ) {
    return _assembly.detailService.getRevisionDetail(historyId: historyId);
  }

  AsyncDBResult<Unit> restoreRevision({
    required String historyId,
    bool recreate = false,
  }) {
    return _assembly.restoreService.restoreRevision(
      historyId: historyId,
      recreate: recreate,
    );
  }

  AsyncDBResult<Unit> deleteRevision(String historyId) {
    return _assembly.deleteService.deleteRevision(historyId);
  }

  AsyncDBResult<Unit> clearItemHistory({
    required String itemId,
    required VaultItemType type,
  }) {
    return _assembly.deleteService.clearItemHistory(itemId: itemId, type: type);
  }

  AsyncDBResult<Unit> maybeCleanup() {
    return _assembly.retentionService.maybeCleanup();
  }

  AsyncDBResult<Unit> cleanupByItemLimit({
    required String itemId,
    required VaultItemType type,
    required int limit,
  }) {
    return _assembly.retentionService.cleanupByItemLimit(
      itemId: itemId,
      type: type,
      limit: limit,
    );
  }

  AsyncDBResult<Unit> cleanupByMaxAge({required int maxAgeDays}) {
    return _assembly.retentionService.cleanupByMaxAge(maxAgeDays: maxAgeDays);
  }
}
