import '../../../tables/vault_items/vault_items.dart';
import '../../../tables/wifi/wifi_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class WifiHistoryPayload extends HistoryPayload {
  const WifiHistoryPayload({
    required this.ssid,
    this.password,
    this.securityType,
    this.securityTypeOther,
    this.encryption,
    this.encryptionOther,
    required this.hiddenSsid,
  });

  final String ssid;
  final String? password;
  final WifiSecurityType? securityType;
  final String? securityTypeOther;
  final WifiEncryptionType? encryption;
  final String? encryptionOther;
  final bool hiddenSsid;

  @override
  VaultItemType get type => VaultItemType.wifi;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'wifi.ssid',
        label: 'SSID',
        value: ssid,
      ),
      HistoryFieldSnapshot<String>(
        key: 'wifi.password',
        label: 'Password',
        value: password,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'wifi.securityType',
        label: 'Security type',
        value: securityType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'wifi.securityTypeOther',
        label: 'Security type other',
        value: securityTypeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'wifi.encryption',
        label: 'Encryption',
        value: encryption?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'wifi.encryptionOther',
        label: 'Encryption other',
        value: encryptionOther,
      ),
      HistoryFieldSnapshot<bool>(
        key: 'wifi.hiddenSsid',
        label: 'Hidden SSID',
        value: hiddenSsid,
      ),
    ];
  }
}
