import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/recovery_codes_history_payload.dart';
import 'vault_history_restore_handler.dart';

class RecoveryCodesHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  RecoveryCodesHistoryRestoreHandler({
    required this.recoveryCodesItemsDao,
    required this.recoveryCodesDao,
    required this.recoveryCodeValuesHistoryDao,
  });

  final RecoveryCodesItemsDao recoveryCodesItemsDao;
  final RecoveryCodesDao recoveryCodesDao;
  final RecoveryCodeValuesHistoryDao recoveryCodeValuesHistoryDao;

  @override
  VaultItemType get type => VaultItemType.recoveryCodes;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
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

    final historyValues = await recoveryCodeValuesHistoryDao
        .getRecoveryCodeValuesByHistoryId(base.historyId);

    if (payload.codesCount != null &&
        payload.codesCount! > 0 &&
        historyValues.isEmpty) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_recovery_code_value',
          message:
              'Нельзя восстановить recovery codes: в снимке отсутствуют значения кодов',
          entity: 'recoveryCodes',
        ),
      );
    }

    if (historyValues.any((v) => v.code == null)) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_recovery_code_value',
          message:
              'Нельзя восстановить recovery codes: в снимке отсутствуют значения кодов',
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

    final liveValues = historyValues
        .map(
          (h) => RecoveryCodesCompanion(
            itemId: Value(base.itemId),
            code: Value(h.code!),
            used: Value(h.used),
            usedAt: Value(h.usedAt),
            position: Value(h.position),
          ),
        )
        .toList();

    await recoveryCodesDao.replaceRecoveryCodesForItem(
      itemId: base.itemId,
      codes: liveValues,
    );

    return const Success(unit);
  }
}
