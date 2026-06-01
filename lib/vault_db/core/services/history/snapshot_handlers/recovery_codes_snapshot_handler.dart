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
  RecoveryCodesSnapshotHandler({required this.recoveryCodesHistoryDao});

  final RecoveryCodesHistoryDao recoveryCodesHistoryDao;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  AsyncDBResult<Unit> writeTypeSnapshot({
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
            generatedAt: Value(rc.generatedAt),
            oneTime: Value(rc.oneTime),
          ),
        );

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
