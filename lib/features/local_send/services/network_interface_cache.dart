import 'dart:io';

import 'package:hoplixi/core/logger/logger.dart';

/// Возвращает приоритетный балл интерфейса по имени.
///
/// Меньше — лучше. 0 = реальный LAN, 50 = неизвестный, ≥ 100 = VPN/virtual.
int interfaceScore(String name) {
  const vpnPatterns = [
    'tun',
    'tap',
    'utun',
    'ppp',
    'ipsec',
    'l2tp',
    'sstp',
    'openvpn',
    'wireguard',
    'nordlynx',
    'wg',
    'vpn',
    'veth',
    'docker',
    'virbr',
    'vmnet',
    'vboxnet',
    'hyperv',
  ];
  for (final pat in vpnPatterns) {
    if (name.startsWith(pat) || name.contains(pat)) return 100;
  }

  const lanPatterns = [
    'en',
    'eth',
    'wlan',
    'wifi',
    'wlp',
    'enp',
    'eno',
    'ens',
    'wi-fi',
    'ethernet',
    'local area connection',
    'беспроводная',
  ];
  for (final pat in lanPatterns) {
    if (name.startsWith(pat) || name.contains(pat)) return 0;
  }

  return 50;
}

/// Кэш результата [NetworkInterface.list(type: IPv4)].
///
/// Сам по себе вызов [NetworkInterface.list()] — дорогой:
/// обновляем не чаще чем раз в [ttl] (по умолчанию 30 с).
/// При смене сети вызывайте [invalidate()].
class NetworkInterfaceCache {
  static const _defaultTtl = Duration(seconds: 30);

  final Duration ttl;
  List<NetworkInterface>? _cached;
  DateTime? _cachedAt;

  NetworkInterfaceCache({this.ttl = _defaultTtl});

  /// Возвращает список IPv4-интерфейсов (из кэша если не устарел).
  Future<List<NetworkInterface>> list() async {
    final now = DateTime.now();
    if (_cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < ttl) {
      return _cached!;
    }
    _cached = await NetworkInterface.list(type: InternetAddressType.IPv4);
    _cachedAt = now;
    return _cached!;
  }

  /// Находит интерфейс по IPv4-адресу (использует кэш).
  ///
  /// Возвращает null если [ip] пустой, '0.0.0.0' или не найден.
  Future<NetworkInterface?> findByIp(String ip) async {
    if (ip.isEmpty || ip == '0.0.0.0') return null;
    final interfaces = await list();
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.address == ip) return iface;
      }
    }
    logError(
      'NetworkInterfaceCache: interface with IP $ip not found, '
      'mDNS will use all interfaces',
    );
    return null;
  }

  /// Сбрасывает кэш — следующий [list()] сделает реальный вызов.
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }
}
