import 'package:hoplixi/main_db/core/repositories/base/wifi_repository.dart';

import '../../../daos/daos.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_payload.dart';
import '../payloads/wifi_history_payload.dart';
import 'vault_history_type_normalizer.dart';

class WifiHistoryNormalizer implements VaultHistoryTypeNormalizer {
  WifiHistoryNormalizer({
    required this.wifiHistoryDao,
    required this.wifiRepository,
  });

  final WifiHistoryDao wifiHistoryDao;
  final WifiRepository wifiRepository;

  @override
  VaultItemType get type => VaultItemType.wifi;

  @override
  Future<HistoryPayload?> normalizeHistory({
    required String historyId,
  }) async {
    final rows = await wifiHistoryDao.getWifiHistoryByHistoryIds([historyId]);
    if (rows.isEmpty) return null;

    final item = rows.first;

    return WifiHistoryPayload(
      ssid: item.ssid,
      password: item.password,
      securityType: item.securityType,
      securityTypeOther: item.securityTypeOther,
      encryption: item.encryption,
      encryptionOther: item.encryptionOther,
      hiddenSsid: item.hiddenSsid,
    );
  }

  @override
  Future<HistoryPayload?> normalizeCurrent({
    required String itemId,
  }) async {
    final view = await wifiRepository.getViewById(itemId);
    if (view == null) return null;

    final item = view.wifi;

    return WifiHistoryPayload(
      ssid: item.ssid,
      password: item.password,
      securityType: item.securityType,
      securityTypeOther: item.securityTypeOther,
      encryption: item.encryption,
      encryptionOther: item.encryptionOther,
      hiddenSsid: item.hiddenSsid,
    );
  }
}
