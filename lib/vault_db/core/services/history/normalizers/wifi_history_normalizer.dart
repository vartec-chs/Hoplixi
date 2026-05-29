import 'package:hoplixi/vault_db/core/repositories/base/wifi_repository.dart';

import '../../../daos/daos.dart';
import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../scheme/tables/vault_items/vault_items.dart';
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
  AsyncDBResult<Optional<HistoryPayload>> normalizeHistory({
    required String historyId,
  }) {
    return tryCatchAsync(
      () async {
        final rows = await wifiHistoryDao.getWifiHistoryByHistoryIds([
          historyId,
        ]);
        if (rows.isEmpty) return const None();

        final item = rows.first;

        return Some(
          WifiHistoryPayload(
            ssid: item.ssid,
            password: item.password,
            securityType: item.securityType,
            securityTypeOther: item.securityTypeOther,
            encryption: item.encryption,
            encryptionOther: item.encryptionOther,
            hiddenSsid: item.hiddenSsid,
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации истории Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  @override
  AsyncDBResult<Optional<HistoryPayload>> normalizeCurrent({
    required String itemId,
  }) {
    return tryCatchAsync(
      () async {
        final viewOpt = (await wifiRepository.getViewById(itemId)).getOrThrow();
        return viewOpt.fold((view) {
          final item = view.wifi;
          return Some(
            WifiHistoryPayload(
              ssid: item.ssid,
              password: item.password,
              securityType: item.securityType,
              securityTypeOther: item.securityTypeOther,
              encryption: item.encryption,
              encryptionOther: item.encryptionOther,
              hiddenSsid: item.hiddenSsid,
            ),
          );
        }, () => const None());
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при нормализации текущего состояния Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
