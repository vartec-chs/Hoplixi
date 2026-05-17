import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/license_key_history_payload.dart';
import 'vault_history_restore_handler.dart';

class LicenseKeyHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  LicenseKeyHistoryRestoreHandler({
    required this.licenseKeyItemsDao,
  });

  final LicenseKeyItemsDao licenseKeyItemsDao;

  @override
  VaultItemType get type => VaultItemType.licenseKey;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! LicenseKeyHistoryPayload) {
      return Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for LicenseKey restore',
          entity: 'licenseKey',
        ),
      );
    }

    if (payload.licenseKey == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message: 'Нельзя восстановить лицензию: отсутствует ключ',
          entity: 'licenseKey',
        ),
      );
    }

    await licenseKeyItemsDao.upsertLicenseKeyItem(
      LicenseKeyItemsCompanion(
        itemId: Value(base.itemId),
        productName: Value(payload.productName),
        vendor: Value(payload.vendor),
        licenseKey: Value(payload.licenseKey!),
        licenseType: Value(payload.licenseType),
        licenseTypeOther: Value(payload.licenseTypeOther),
        accountEmail: Value(payload.accountEmail),
        accountUsername: Value(payload.accountUsername),
        purchaseEmail: Value(payload.purchaseEmail),
        orderNumber: Value(payload.orderNumber),
        purchaseDate: Value(payload.purchaseDate),
        purchasePrice: Value(payload.purchasePrice),
        currency: Value(payload.currency),
        validFrom: Value(payload.validFrom),
        validTo: Value(payload.validTo),
        renewalDate: Value(payload.renewalDate),
        seats: Value(payload.seats),
        activationLimit: Value(payload.activationLimit),
        activationsUsed: Value(payload.activationsUsed),
      ),
    );

    return const Success(unit);
  }
}
