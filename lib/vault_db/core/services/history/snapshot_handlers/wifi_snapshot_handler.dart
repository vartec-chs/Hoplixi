import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../scheme/tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class WifiSnapshotHandler implements VaultSnapshotTypeHandler {
  WifiSnapshotHandler({required this.wifiHistoryDao});

  final WifiHistoryDao wifiHistoryDao;

  @override
  VaultItemType get type => VaultItemType.wifi;

  @override
  AsyncDbResult<Unit> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        if (view is! WifiViewDto) {
          throw const DBCoreError.conflict(
            code: 'history.snapshot.invalid_view_type',
            message: 'Invalid view type for Wifi snapshot',
            entity: 'wifi',
          );
        }

        final wifi = view.wifi;

        await wifiHistoryDao.insertWifiHistory(
          WifiHistoryCompanion.insert(
            historyId: historyId,
            ssid: wifi.ssid,
            password: Value(includeSecrets ? wifi.password : null),
            securityType: Value(wifi.securityType),
            securityTypeOther: Value(wifi.securityTypeOther),
            encryption: Value(wifi.encryption),
            encryptionOther: Value(wifi.encryptionOther),
            hiddenSsid: Value(wifi.hiddenSsid),
          ),
        );

        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при записи снимка Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
