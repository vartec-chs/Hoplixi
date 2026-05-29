import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class LicenseKeySnapshotHandler implements VaultSnapshotTypeHandler {
  LicenseKeySnapshotHandler({required this.licenseKeyHistoryDao});

  final LicenseKeyHistoryDao licenseKeyHistoryDao;

  @override
  VaultItemType get type => VaultItemType.licenseKey;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return tryCatchAsync(
      () async {
        if (view is! LicenseKeyViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for LicenseKey snapshot',
            entity: 'licenseKey',
          );
        }

        final lk = view.licenseKey;

        await licenseKeyHistoryDao.insertLicenseKeyHistory(
          LicenseKeyHistoryCompanion.insert(
            historyId: historyId,
            productName: lk.productName,
            vendor: Value(lk.vendor),
            licenseKey: Value(includeSecrets ? lk.licenseKey : null),
            licenseType: Value(lk.licenseType),
            licenseTypeOther: Value(lk.licenseTypeOther),
            accountEmail: Value(lk.accountEmail),
            accountUsername: Value(lk.accountUsername),
            purchaseEmail: Value(lk.purchaseEmail),
            orderNumber: Value(lk.orderNumber),
            purchaseDate: Value(lk.purchaseDate),
            purchasePrice: Value(lk.purchasePrice),
            currency: Value(lk.currency),
            validFrom: Value(lk.validFrom),
            validTo: Value(lk.validTo),
            renewalDate: Value(lk.renewalDate),
            seats: Value(lk.seats),
            activationLimit: Value(lk.activationLimit),
            activationsUsed: Value(lk.activationsUsed),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
