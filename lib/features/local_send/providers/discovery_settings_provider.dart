import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCustomDeviceNameKey = 'local_send.custom_device_name';
const _kForcedIpKey = 'local_send.forced_ip';

/// Настройки обнаружения устройств в локальной сети.
class DiscoverySettings {
  const DiscoverySettings({this.customDeviceName, this.forcedIp});

  /// Пользовательское имя устройства в mDNS.
  /// Если null — используется [Platform.localHostname].
  final String? customDeviceName;

  /// Принудительный IP-адрес для рекламы и сканирования.
  /// Если null — используется автоопределение.
  ///
  /// ⚠️ Экспериментальная функция.
  final String? forcedIp;

  DiscoverySettings copyWith({
    Object? customDeviceName = _sentinel,
    Object? forcedIp = _sentinel,
  }) {
    return DiscoverySettings(
      customDeviceName: customDeviceName == _sentinel
          ? this.customDeviceName
          : customDeviceName as String?,
      forcedIp: forcedIp == _sentinel ? this.forcedIp : forcedIp as String?,
    );
  }
}

const _sentinel = Object();

/// Запись о сетевом интерфейсе с IPv4-адресом.
class NetworkInterfaceEntry {
  const NetworkInterfaceEntry({required this.ip, required this.ifaceName});

  final String ip;
  final String ifaceName;

  String get displayLabel => '$ifaceName  ($ip)';
}

/// Список доступных IPv4-интерфейсов (без loopback).
final networkInterfacesProvider = FutureProvider<List<NetworkInterfaceEntry>>((
  ref,
) async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  final result = <NetworkInterfaceEntry>[];
  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      if (!addr.isLoopback) {
        result.add(
          NetworkInterfaceEntry(ip: addr.address, ifaceName: iface.name),
        );
      }
    }
  }
  return result;
});

/// Провайдер настроек обнаружения (имя устройства, принудительный IP).
///
/// Сохраняет данные в [SharedPreferences].
final discoverySettingsProvider =
    AsyncNotifierProvider<DiscoverySettingsNotifier, DiscoverySettings>(
      DiscoverySettingsNotifier.new,
    );

class DiscoverySettingsNotifier extends AsyncNotifier<DiscoverySettings> {
  @override
  Future<DiscoverySettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return DiscoverySettings(
      customDeviceName: prefs.getString(_kCustomDeviceNameKey),
      forcedIp: prefs.getString(_kForcedIpKey),
    );
  }

  /// Устанавливает пользовательское имя устройства в mDNS.
  /// Передайте null или пустую строку, чтобы сбросить до hostname.
  Future<void> setDeviceName(String? name) async {
    final trimmed = name?.trim();
    final prefs = await SharedPreferences.getInstance();

    if (trimmed == null || trimmed.isEmpty) {
      await prefs.remove(_kCustomDeviceNameKey);
    } else {
      await prefs.setString(_kCustomDeviceNameKey, trimmed);
    }

    state = AsyncData(
      DiscoverySettings(
        customDeviceName: (trimmed?.isNotEmpty ?? false) ? trimmed : null,
        forcedIp: state.value?.forcedIp,
      ),
    );
  }

  /// Устанавливает принудительный IP-адрес (экспериментально).
  /// Передайте null или пустую строку, чтобы вернуться к автоопределению.
  Future<void> setForcedIp(String? ip) async {
    final prefs = await SharedPreferences.getInstance();

    if (ip == null || ip.isEmpty) {
      await prefs.remove(_kForcedIpKey);
    } else {
      await prefs.setString(_kForcedIpKey, ip);
    }

    state = AsyncData(
      DiscoverySettings(
        customDeviceName: state.value?.customDeviceName,
        forcedIp: (ip != null && ip.isNotEmpty) ? ip : null,
      ),
    );
  }
}
