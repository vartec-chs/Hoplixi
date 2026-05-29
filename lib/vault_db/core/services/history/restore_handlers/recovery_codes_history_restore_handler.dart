import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/recovery_codes_history_payload.dart';
import 'vault_history_restore_handler.dart';

class RecoveryCodesHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  RecoveryCodesHistoryRestoreHandler({
    required this.recoveryCodesItemsDao,
    required this.recoveryCodesDao,
  });

  final RecoveryCodesItemsDao recoveryCodesItemsDao;
  final RecoveryCodesDao recoveryCodesDao;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  Future<DBResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! RecoveryCodesHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for RecoveryCodes restore',
          entity: 'recoveryCodes',
        ),
      );
    }

    await recoveryCodesItemsDao.upsertRecoveryCodesItem(
      RecoveryCodesItemsCompanion(
        itemId: Value(base.itemId),
        generatedAt: Value(payload.generatedAt),
        oneTime: Value(payload.oneTime ?? false),
      ),
    );

    return const Success(unit);
  }
}
