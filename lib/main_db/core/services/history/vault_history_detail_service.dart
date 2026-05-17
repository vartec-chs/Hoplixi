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

      // TODO: Load compare target (newer revision or current live)
      // For now, compare with empty snapshot or placeholder
      final emptySnapshot = NormalizedHistorySnapshot(
        snapshot: selected.snapshot,
        fields: const {},
        sensitiveKeys: const {},
        customFields: const [],
        restoreWarnings: const [],
      );

      final fieldDiffs = diffService.buildFieldDiffs(
        current: emptySnapshot,
        replacement: selected,
      );

      return Success(
        VaultHistoryRevisionDetailDto(
          selected: selected.snapshot,
          compareTargetKind:
              HistoryCompareTargetKind.currentLive, // Placeholder
          fieldDiffs: fieldDiffs,
          customFieldDiffs: const [],
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
