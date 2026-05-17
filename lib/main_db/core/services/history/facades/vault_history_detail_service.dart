import 'package:result_dart/result_dart.dart';
import '../../../errors/db_result.dart';
import '../../../errors/db_error.dart';
import '../../../models/dto_history/cards/vault_history_revision_detail_dto.dart';
import '../../../models/mappers/history/vault_item_base_history_payload_mapper.dart';
import '../models/normalized_history_snapshot.dart';
import '../payloads/empty_history_payload.dart';
import '../utils/vault_history_diff_service.dart';
import '../vault_history_normalized_loader.dart';
import '../policy/vault_history_restore_policy_service.dart';

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
          selected: selected.base.toVaultSnapshotCardDto(),
          compareTargetKind: current != null
              ? HistoryCompareTargetKind.currentLive
              : HistoryCompareTargetKind.deletedState,
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
