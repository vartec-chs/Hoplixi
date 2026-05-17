import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/otp_history_payload.dart';
import 'vault_history_restore_handler.dart';

class OtpHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  OtpHistoryRestoreHandler({required this.otpItemsDao});

  final OtpItemsDao otpItemsDao;

  @override
  VaultItemType get type => VaultItemType.otp;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! OtpHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Otp restore',
          entity: 'otp',
        ),
      );
    }

    if (payload.otpType == null ||
        payload.secret == null ||
        payload.algorithm == null ||
        payload.digits == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message:
              'Нельзя восстановить запись: в снимке отсутствуют обязательные поля OTP',
          entity: 'otp',
        ),
      );
    }

    await otpItemsDao.upsertOtpItem(
      OtpItemsCompanion(
        itemId: Value(base.itemId),
        type: Value(payload.otpType!),
        issuer: Value(payload.issuer),
        accountName: Value(payload.accountName),
        secret: Value(payload.secret!),
        algorithm: Value(payload.algorithm!),
        digits: Value(payload.digits!),
        period: Value(payload.period),
        counter: Value(payload.counter),
      ),
    );

    return const Success(unit);
  }
}
