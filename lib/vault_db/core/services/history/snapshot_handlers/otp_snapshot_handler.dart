import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class OtpSnapshotHandler implements VaultSnapshotTypeHandler {
  OtpSnapshotHandler({required this.otpHistoryDao});

  final OtpHistoryDao otpHistoryDao;

  @override
  VaultItemType get type => VaultItemType.otp;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! OtpViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Otp snapshot',
            entity: 'otp',
          );
        }

        final otp = view.otp;

        await otpHistoryDao.insertOtpHistory(
          OtpHistoryCompanion.insert(
            historyId: historyId,
            type: Value(otp.type),
            issuer: Value(otp.issuer),
            accountName: Value(otp.accountName),
            secret: Value(includeSecrets ? otp.secret : null),
            algorithm: Value(otp.algorithm),
            digits: Value(otp.digits),
            period: Value(otp.period),
            counter: Value(otp.counter),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка OTP',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
