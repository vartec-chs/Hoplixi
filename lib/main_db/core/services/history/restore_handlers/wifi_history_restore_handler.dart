import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../tables/tables.dart';
import '../models/history_payload.dart';
import '../models/vault_item_base_history_payload.dart';
import '../payloads/wifi_history_payload.dart';
import 'vault_history_restore_handler.dart';

class WifiHistoryRestoreHandler implements VaultHistoryRestoreHandler {
  WifiHistoryRestoreHandler({required this.wifiItemsDao});

  final WifiItemsDao wifiItemsDao;

  @override
  VaultItemType get type => VaultItemType.wifi;

  @override
  Future<DbResult<Unit>> restoreTypeSpecific({
    required VaultItemBaseHistoryPayload base,
    required HistoryPayload payload,
  }) async {
    if (payload is! WifiHistoryPayload) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.invalid_payload',
          message: 'Invalid payload for Wifi restore',
          entity: 'wifi',
        ),
      );
    }

    if (payload.ssid.isEmpty || payload.password == null) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.restore.missing_field',
          message:
              'Нельзя восстановить запись: в снимке отсутствуют обязательные поля WiFi',
          entity: 'wifi',
        ),
      );
    }

    await wifiItemsDao.upsertWifiItem(
      WifiItemsCompanion(
        itemId: Value(base.itemId),
        ssid: Value(payload.ssid),
        password: Value(payload.password!),
        securityType: Value(payload.securityType),
        securityTypeOther: Value(payload.securityTypeOther),
        encryption: Value(payload.encryption),
        encryptionOther: Value(payload.encryptionOther),
        hiddenSsid: Value(payload.hiddenSsid),
      ),
    );

    return const Success(unit);
  }
}
