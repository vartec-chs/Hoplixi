import 'package:result_dart/result_dart.dart';
import '../../errors/db_result.dart';
import '../../models/dto_history/cards/cards_exports.dart';
import '../../models/filters/history/vault_snapshot_history_filter.dart';
import 'vault_history_read_service.dart';

class VaultHistoryTimelineService {
  VaultHistoryTimelineService({
    required this.readService,
  });

  final VaultHistoryReadService readService;

  Future<DbResult<List<VaultHistoryTimelineItemDto>>> getTimeline(
    VaultSnapshotHistoryFilter filter,
  ) async {
    return (await readService.getFilteredCards(filter)).map((cards) {
      return cards.map((card) {
        final snapshot = card.snapshot;
        return VaultHistoryTimelineItemDto(
          historyId: snapshot.historyId,
          itemId: snapshot.itemId,
          type: snapshot.type,
          action: snapshot.action,
          title: snapshot.name,
          subtitle: snapshot.description,
          actionAt: snapshot.historyCreatedAt,
          // TODO: Implement diff calculation to fill these
          changedFieldsCount: 0,
          changedFieldLabels: const [],
          isRestorable: _isRestorable(card),
          restoreWarnings: _restoreWarnings(card),
        );
      }).toList();
    });
  }

  bool _isRestorable(VaultHistoryCardDto card) {
    // Stage 1: Basic restorable logic
    return true;
  }

  List<String> _restoreWarnings(VaultHistoryCardDto card) {
    return const [];
  }
}
