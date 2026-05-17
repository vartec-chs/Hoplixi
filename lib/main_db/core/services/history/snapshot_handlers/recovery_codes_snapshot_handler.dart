import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class RecoveryCodesSnapshotHandler implements VaultSnapshotTypeHandler {
  RecoveryCodesSnapshotHandler({
    required this.recoveryCodesHistoryDao,
    required this.recoveryCodeValuesHistoryDao,
  });

  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;
  final RecoveryCodeValuesHistoryDao recoveryCodeValuesHistoryDao;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! RecoveryCodesViewDto) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for RecoveryCodes snapshot',
          entity: 'recoveryCodes',
        ),
      );
    }

    final rc = view.recoveryCodes;

    await recoveryCodesHistoryDao.insertRecoveryCodesHistory(
      RecoveryCodesHistoryCompanion.insert(
        historyId: historyId,
        codesCount: Value(rc.codesCount),
        usedCount: Value(rc.usedCount),
        generatedAt: Value(rc.generatedAt),
        oneTime: Value(rc.oneTime),
      ),
    );

    if (view.codes.isNotEmpty) {
      final codeCompanions = view.codes
          .map(
            (c) => RecoveryCodeValuesHistoryCompanion.insert(
              historyId: historyId,
              originalCodeId: Value(c.id),
              code: Value(includeSecrets ? c.code : null),
              used: Value(c.used),
              usedAt: Value(c.usedAt),
              position: Value(c.position),
            ),
          )
          .toList();
      await recoveryCodeValuesHistoryDao.insertRecoveryCodeValuesHistoryBatch(
        codeCompanions,
      );
    }

    return const Success(unit);
  }
}
