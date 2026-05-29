import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
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
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return tryCatchAsync(
      () async {
        if (view is! RecoveryCodesViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for RecoveryCodes snapshot',
            entity: 'recoveryCodes',
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
          await recoveryCodeValuesHistoryDao
              .insertRecoveryCodeValuesHistoryBatch(codeCompanions);
        }

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка кодов восстановления',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
