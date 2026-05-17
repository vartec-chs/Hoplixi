import 'package:hoplixi/main_db/core/services/history/history_services.dart';
import 'package:result_dart/result_dart.dart';
import '../../errors/db_result.dart';
import '../../errors/db_error.dart';
import '../../models/dto_history/cards/vault_history_revision_detail_dto.dart';
import 'vault_history_normalized_loader.dart';
import 'vault_history_diff_service.dart';
import 'vault_history_restore_policy_service.dart';

class VaultHistoryDetailService {
  VaultHistoryDetailService({
    required this.loader,
    required this.diffService,
    required this.restorePolicy,
  });

  final VaultHistoryNormalizedLoader loader;
  final VaultHistoryDiffService diffService;
  final VaultHistoryRestorePolicyService restorePolicy;

  Future<DbResult<VaultHistoryRevisionDetailDto>> getRevisionDetail({
    required String historyId,
  }) async {
    try {
      final selected = await loader.loadHistorySnapshot(historyId);
      if (selected == null) {
        return Failure(
          DBCoreError.notFound(entity: 'HistorySnapshot', id: historyId),
        );
      }

      // Load compare target (newer revision or current live)
      // For now, we only have comparison with current live as a concept
      final current = await loader.loadCurrentSnapshot(
        itemId: selected.base.itemId,
        type: selected.base.type,
      );

      final AnyNormalizedHistorySnapshot compareTarget =
          current ??
          NormalizedHistorySnapshot(
            base: selected.base,
            payload: EmptyHistoryPayload(selected.base.type),
            customFields: const [],
            restoreWarnings: const [],
          );

      final fieldDiffs = diffService.buildFieldDiffs(
        current: compareTarget,
        replacement: selected,
      );

      final customFieldDiffs = diffService.buildCustomFieldDiffs(
        current: compareTarget,
        replacement: selected,
      );

      return Success(
        VaultHistoryRevisionDetailDto(
          selected: selected.base.historyId, // Changed to string historyId
          compareTargetKind:
              current != null
                  ? HistoryCompareTargetKind.currentLive
                  : HistoryCompareTargetKind.none,
          fieldDiffs: fieldDiffs,
          customFieldDiffs: customFieldDiffs,
          isRestorable: restorePolicy.isRestorable(selected),
          restoreWarnings: restorePolicy.restoreWarnings(selected),
        ),
      );
    } catch (e, s) {
      return Failure(
        DBCoreError.unknown(message: e.toString(), cause: e, stackTrace: s),
      );
    }
  }
}
