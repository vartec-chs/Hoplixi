import 'dart:async';
import 'dart:io';

import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:mdns_dart/mdns_dart.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Тип mDNS-сервиса для обнаружения устройств Hoplixi.
const String kServiceType = '_hoplixi._tcp';

/// Сервис обнаружения устройств в локальной сети через mDNS.
///
/// Использует [MDNSServer] для рекламы текущего устройства
/// и [MDNSClient] для периодического поиска других устройств.
class DiscoveryService {
  MDNSServer? _server;
  Timer? _discoveryTimer;

  final _devicesController = StreamController<DeviceInfo>.broadcast();

  /// Стрим найденных устройств.
  Stream<DeviceInfo> get devicesStream => _devicesController.stream;

  /// Получает локальный IPv4-адрес устройства.
  ///
  /// Предпочитает реальные LAN-интерфейсы (Wi-Fi, Ethernet)
  /// и пропускает VPN/tunnel-интерфейсы (tun, tap, utun, ppp и т.д.),
  /// которые не поддерживают mDNS multicast.
  ///
  /// На мобильных платформах использует [NetworkInfo] для получения
  /// Wi-Fi IP (требует разрешение на геолокацию).
  /// На десктопе — [NetworkInterface.list()] с фильтрацией.
  Future<String> getLocalIp() async {
    // На мобильных платформах пробуем network_info_plus
    // (требует location permission).
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final status = await Permission.locationWhenInUse.request();

        if (status.isGranted) {
          final info = NetworkInfo();
          final wifiIp = await info.getWifiIP();

          if (wifiIp != null && wifiIp.isNotEmpty) {
            return wifiIp;
          }
        }
      } catch (_) {
        // Fallback ниже.
      }
    }

    // Fallback: перебираем сетевые интерфейсы с приоритизацией LAN.
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );

    // Приоритет 0 (лучший) → 3 (худший).
    NetworkInterface? best;
    int bestScore = 999;

    for (final iface in interfaces) {
      final name = iface.name.toLowerCase();
      final score = _interfaceScore(name);
      if (score < bestScore) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            bestScore = score;
            best = iface;
            break;
          }
        }
      }
    }

    if (best != null) {
      for (final addr in best.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }

    return '0.0.0.0';
  }

  /// Возвращает приоритетный балл интерфейса.
  /// Меньше — лучше. VPN/tunnel-интерфейсы получают высокий балл.
  int _interfaceScore(String name) {
    // Явные VPN / tunnel интерфейсы — пропускаем в последнюю очередь.
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

    // Реальные Wi-Fi / Ethernet интерфейсы — высший приоритет.
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

    // Прочие — средний приоритет.
    return 50;
  }

  /// Начинает рекламу текущего устройства через mDNS.
  ///
  /// [selfInfo] содержит метаданные устройства,
  /// которые публикуются в TXT-записях.
  Future<void> startAdvertising(DeviceInfo selfInfo) async {
    // Останавливаем предыдущий сервер при перезапуске.
    await _stopServer();

    try {
      final ip = InternetAddress(selfInfo.ip);

      final txtRecords = MDNSService.createTXTRecords({
        'id': selfInfo.id,
        'name': selfInfo.name,
        'platform': selfInfo.platform,
        'signalingPort': selfInfo.signalingPort.toString(),
      });

      final service = await MDNSService.create(
        instance: selfInfo.name,
        service: kServiceType,
        port: selfInfo.signalingPort,
        ips: [ip],
        txt: txtRecords,
      );

      _server = MDNSServer(MDNSServerConfig(zone: service, reuseAddress: true));

      await _server!.start();

      logInfo('DiscoveryService: mDNS advertising started');
    } catch (e) {
      logError('DiscoveryService: failed to start advertising', error: e);
    }
  }

  /// Запускает периодическое сканирование mDNS-сервисов.
  ///
  /// [selfId] — ID текущего устройства (чтобы игнорировать
  /// свои собственные записи).
  Future<void> startDiscovery(String selfId) async {
    // Останавливаем предыдущее сканирование.
    _discoveryTimer?.cancel();
    _discoveryTimer = null;

    // Первый скан сразу.
    await _performDiscovery(selfId);

    // Периодическое сканирование каждые 3 секунды.
    _discoveryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _performDiscovery(selfId),
    );

    logInfo('DiscoveryService: discovery started');
  }

  /// Выполняет одно сканирование mDNS.
  Future<void> _performDiscovery(String selfId) async {
    try {
      final results = await MDNSClient.discover(
        kServiceType,
        timeout: const Duration(seconds: 2),
        reuseAddress: true,
      );

      for (final entry in results) {
        final device = _parseServiceEntry(entry);
        if (device == null) continue;

        // Игнорируем свои записи.
        if (device.id == selfId) continue;

        _devicesController.add(device);
      }
    } catch (e) {
      logError('DiscoveryService: discovery scan error', error: e);
    }
  }

  /// Парсит [ServiceEntry] в [DeviceInfo].
  ///
  /// Считывает метаданные из TXT-записей.
  DeviceInfo? _parseServiceEntry(ServiceEntry entry) {
    final address = entry.primaryAddress?.address;
    if (address == null || entry.port == 0) return null;

    final txtMap = MDNSService.parseTXTRecords(entry.infoFields);

    final id = txtMap['id'];
    final name = txtMap['name'] ?? entry.name;
    final platform = txtMap['platform'] ?? 'unknown';
    final signalingPortStr = txtMap['signalingPort'];
    final signalingPort = signalingPortStr != null
        ? int.tryParse(signalingPortStr)
        : null;

    if (id == null || signalingPort == null) return null;

    return DeviceInfo(
      id: id,
      name: name,
      ip: address,
      signalingPort: signalingPort,
      platform: platform,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Останавливает mDNS-сервер.
  Future<void> _stopServer() async {
    await _server?.stop();
    _server = null;
  }

  /// Останавливает сервер и сканирование.
  Future<void> dispose() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;

    await _stopServer();

    await _devicesController.close();

    logInfo('DiscoveryService: disposed');
  }
}
