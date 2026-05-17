import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class OtpSnapshotHandler implements VaultSnapshotTypeHandler {
  OtpSnapshotHandler({required this.otpHistoryDao});

  final OtpHistoryDao otpHistoryDao;

  @override
  VaultItemType get type => VaultItemType.otp;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! OtpViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Otp snapshot',
          entity: 'otp',
        ),
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

    return const Success(unit);
  }
}
