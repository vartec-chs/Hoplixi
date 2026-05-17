import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:result_dart/result_dart.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/dto.dart';
import '../../../tables/tables.dart';
import 'vault_snapshot_type_handler.dart';

class WifiSnapshotHandler implements VaultSnapshotTypeHandler {
  WifiSnapshotHandler({required this.wifiHistoryDao});

  final WifiHistoryDao wifiHistoryDao;

  @override
  VaultItemType get type => VaultItemType.wifi;

  @override
  Future<DbResult<Unit>> writeTypeSnapshot({
    required String historyId,
    required VaultEntityViewDto view,
    required bool includeSecrets,
  }) async {
    if (view is! WifiViewDto) {
      return const Failure(
        DBCoreError.conflict(
          code: 'history.snapshot.invalid_view_type',
          message: 'Invalid view type for Wifi snapshot',
          entity: 'wifi',
        ),
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

    return const Success(unit);
  }
}
