import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:mdns_dart/mdns_dart.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Тип mDNS-сервиса для обнаружения устройств Hoplixi.
const String kServiceType = '_hoplixi._tcp';

/// UDP-порт для широковещательного fallback-обнаружения.
const int kBroadcastPort = 45632;

/// Сервис обнаружения устройств в локальной сети через mDNS.
///
/// Использует [MDNSServer] для рекламы текущего устройства
/// и [MDNSClient] для периодического поиска других устройств.
class DiscoveryService {
  MDNSServer? _server;
  Timer? _discoveryTimer;

  /// Активный сетевой интерфейс, используемый для рекламы и сканирования.
  /// null = все интерфейсы (поведение по умолчанию).
  NetworkInterface? _activeInterface;

  /// UDP-сокет для широковещательного fallback-обнаружения.
  RawDatagramSocket? _udpSocket;

  /// Таймер периодической рассылки UDP broadcast-анонсов.
  Timer? _broadcastSendTimer;

  /// ID текущего устройства для фильтрации входящих broadcast-пакетов.
  String? _selfId;

  final _devicesController = StreamController<DeviceInfo>.broadcast();

  /// Стрим найденных устройств.
  Stream<DeviceInfo> get devicesStream => _devicesController.stream;

  /// Находит объект [NetworkInterface] по IPv4-адресу.
  /// Возвращает null если адрес не найден или равен '0.0.0.0'.
  Future<NetworkInterface?> _findInterfaceByIp(String ip) async {
    if (ip.isEmpty || ip == '0.0.0.0') return null;
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.address == ip) return iface;
      }
    }
    logError(
      'DiscoveryService: interface with IP $ip not found, using all interfaces',
    );
    return null;
  }

  /// Получает локальный IPv4-адрес устройства.
  ///
  /// Если передан [forcedIp] — возвращает его без проверок.
  /// Иначе предпочитает реальные LAN-интерфейсы (Wi-Fi, Ethernet)
  /// и пропускает VPN/tunnel-интерфейсы (tun, tap, utun, ppp и т.д.),
  /// которые не поддерживают mDNS multicast.
  ///
  /// На мобильных платформах использует [NetworkInfo] для получения
  /// Wi-Fi IP (требует разрешение на геолокацию).
  /// На десктопе — [NetworkInterface.list()] с фильтрацией.
  Future<String> getLocalIp({String? forcedIp}) async {
    if (forcedIp != null && forcedIp.isNotEmpty) return forcedIp;
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

  /// Преобразует произвольное имя устройства в валидный DNS-лейбл.
  /// Используется как `hostName` в MDNSService.create.
  String _toHostname(String name) {
    var result = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (result.isEmpty) result = 'device';
    // DNS label max 63 chars; trim trailing hyphens after cut
    if (result.length > 63) {
      result = result.substring(0, 63).replaceAll(RegExp(r'-+$'), '');
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // UDP broadcast fallback
  // ---------------------------------------------------------------------------

  /// Создаёт UDP-сокет и запускает listener для приёма broadcast-анонсов.
  ///
  /// Вызывается один раз при старте обнаружения. При повторном вызове
  /// предыдущий сокет закрывается и создаётся новый.
  Future<void> _startBroadcastSocket(String selfId) async {
    _selfId = selfId;
    try {
      _udpSocket?.close();
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kBroadcastPort,
        reuseAddress: true,
      );
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = _udpSocket?.receive();
        if (datagram == null) return;
        _handleBroadcast(datagram);
      });
      logInfo(
        'DiscoveryService: UDP broadcast listener started on port $kBroadcastPort',
      );
    } catch (e) {
      logError(
        'DiscoveryService: failed to start UDP broadcast listener',
        error: e,
      );
    }
  }

  /// Разбирает входящий broadcast-пакет и добавляет устройство в стрим.
  void _handleBroadcast(Datagram datagram) {
    try {
      final map =
          jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      final id = map['id'] as String?;
      if (id == null || id == _selfId) return;
      final signalingPort = (map['signalingPort'] as num?)?.toInt();
      if (signalingPort == null || signalingPort == 0) return;
      _devicesController.add(
        DeviceInfo(
          id: id,
          name: map['name'] as String? ?? 'Unknown',
          ip: datagram.address.address,
          signalingPort: signalingPort,
          platform: map['platform'] as String? ?? 'unknown',
          lastSeen: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {}
  }

  /// Запускает периодическую рассылку UDP broadcast-анонсов каждые 5 секунд.
  void _startBroadcastSender(DeviceInfo selfInfo) {
    _broadcastSendTimer?.cancel();
    _broadcastSendTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendBroadcastAnnounce(selfInfo),
    );
    _sendBroadcastAnnounce(selfInfo);
  }

  /// Вычисляет subnet broadcast IPv4-адрес по IP (эвристика /24).
  /// Возвращает null если адрес некорректен.
  String? _subnetBroadcast(String ipv4) {
    final parts = ipv4.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }

  /// Возвращает список broadcast-адресов для всех LAN-интерфейсов.
  ///
  /// VPN/virtual-интерфейсы (score >= 100) пропускаются.
  /// Fallback: [255.255.255.255] если ни один интерфейс не найден.
  Future<List<InternetAddress>> _broadcastTargets() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final targets = <InternetAddress>{};
    for (final iface in interfaces) {
      if (_interfaceScore(iface.name.toLowerCase()) >= 100) continue;
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        final bc = _subnetBroadcast(addr.address);
        if (bc != null) targets.add(InternetAddress(bc));
      }
    }
    if (targets.isEmpty) targets.add(InternetAddress('255.255.255.255'));
    return targets.toList();
  }

  /// Отправляет один UDP broadcast-пакет на subnet broadcast каждого
  /// активного LAN-интерфейса. Это гарантирует, что пакет уйдёт нужным
  /// интерфейсом, а не дефолтным (VPN/virtual).
  Future<void> _sendBroadcastAnnounce(DeviceInfo selfInfo) async {
    final socket = _udpSocket;
    if (socket == null) return;
    final payload = utf8.encode(
      jsonEncode({
        'id': selfInfo.id,
        'name': selfInfo.name,
        'platform': selfInfo.platform,
        'signalingPort': selfInfo.signalingPort,
      }),
    );
    final targets = await _broadcastTargets();
    for (final target in targets) {
      try {
        socket.send(payload, target, kBroadcastPort);
      } catch (e) {
        logError(
          'DiscoveryService: UDP broadcast send error to ${target.address}',
          error: e,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------

  /// Начинает рекламу текущего устройства через mDNS.
  ///
  /// [selfInfo] содержит метаданные устройства,
  /// которые публикуются в TXT-записях.
  ///
  /// Если [selfInfo.ip] соответствует конкретному интерфейсу,
  /// сервер биндится только на него (multicastInterface).
  Future<void> startAdvertising(DeviceInfo selfInfo) async {
    // Останавливаем предыдущий сервер при перезапуске.
    await _stopServer();

    try {
      final ip = InternetAddress(selfInfo.ip);

      // Резолвим и кэшируем интерфейс для этого IP.
      // Он будет переиспользован в _performDiscovery.
      _activeInterface = await _findInterfaceByIp(selfInfo.ip);

      if (_activeInterface != null) {
        logInfo(
          'DiscoveryService: binding to interface '
          '${_activeInterface!.name} (${selfInfo.ip})',
        );
      }

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
        // Явно задаём hostName, чтобы избежать использования
        // Platform.localHostname = "localhost" на Android/iOS.
        hostName: _toHostname(selfInfo.name),
        ips: [ip],
        txt: txtRecords,
      );

      _server = MDNSServer(
        MDNSServerConfig(
          zone: service,
          networkInterface: _activeInterface,
          reuseAddress: true,
          logger: (text) =>
              logInfo(text, tag: 'DiscoveryService (mDNS Server)'),
        ),
      );

      await _server!.start();

      // Запускаем UDP broadcast-анонс как fallback.
      _startBroadcastSender(selfInfo);

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

    // Запускаем UDP broadcast listener (fallback при недоступности mDNS).
    await _startBroadcastSocket(selfId);

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
        networkInterface: _activeInterface,
        logger: (text) => logInfo(text, tag: 'DiscoveryService (mDNS Client)'),
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

  /// Останавливает mDNS-сервер и broadcast-отправку.
  Future<void> _stopServer() async {
    _broadcastSendTimer?.cancel();
    _broadcastSendTimer = null;
    await _server?.stop();
    _server = null;
  }

  /// Останавливает сервер и сканирование.
  Future<void> dispose() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;

    await _stopServer();

    _udpSocket?.close();
    _udpSocket = null;

    await _devicesController.close();

    logInfo('DiscoveryService: disposed');
  }
}
