import 'dart:io';

import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/local_send/services/network_interface_cache.dart';

/// UDP-порт для широковещательного fallback-обнаружения.
const int kBroadcastPort = 45632;

/// Управляет UDP-сокетами для широковещательного обнаружения устройств.
///
/// На десктопе создаёт отдельный сокет для каждого LAN-интерфейса,
/// что гарантирует отправку broadcast через нужный интерфейс, а не
/// через дефолтный маршрут (VPN/virtual).
///
/// На мобильных платформах (Android/iOS) использует единый anyIPv4 сокет —
/// binding к конкретному IP запрещает broadcast-отправку (errno=1).
class UdpBroadcastTransport {
  final NetworkInterfaceCache _ifaceCache;
  final int port;

  // Ключ — IPv4-адрес интерфейса или '0.0.0.0' для anyIPv4/fallback.
  final Map<String, RawDatagramSocket> _sockets = {};

  UdpBroadcastTransport({
    required NetworkInterfaceCache ifaceCache,
    this.port = kBroadcastPort,
  }) : _ifaceCache = ifaceCache;

  bool get isRunning => _sockets.isNotEmpty;

  /// Создаёт сокеты и запускает прослушивание входящих датаграмм.
  ///
  /// При повторном вызове старые сокеты закрываются.
  /// [onReceive] вызывается для каждой входящей датаграммы.
  Future<void> start({
    required void Function(Datagram datagram) onReceive,
  }) async {
    stop();

    if (Platform.isAndroid || Platform.isIOS) {
      await _bindSocket(
        InternetAddress.anyIPv4,
        '0.0.0.0',
        onReceive: onReceive,
        label: 'anyIPv4 (mobile)',
      );
      return;
    }

    final interfaces = await _ifaceCache.list();
    for (final iface in interfaces) {
      if (interfaceScore(iface.name.toLowerCase()) >= 100) continue;
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        await _bindSocket(
          addr,
          addr.address,
          ifaceName: iface.name,
          onReceive: onReceive,
        );
      }
    }

    if (_sockets.isEmpty) {
      await _bindSocket(
        InternetAddress.anyIPv4,
        '0.0.0.0',
        onReceive: onReceive,
        label: 'anyIPv4 (fallback)',
      );
    }
  }

  /// Отправляет [payload] на subnet broadcast каждого активного интерфейса.
  void send(List<int> payload) {
    for (final entry in _sockets.entries) {
      final bcStr = entry.key == '0.0.0.0'
          ? '255.255.255.255'
          : _subnetBroadcast(entry.key);
      if (bcStr == null) continue;
      try {
        entry.value.send(payload, InternetAddress(bcStr), port);
      } catch (e) {
        logError('UdpBroadcastTransport: send error to $bcStr', error: e);
      }
    }
  }

  /// Закрывает все сокеты.
  void stop() {
    for (final s in _sockets.values) {
      s.close();
    }
    _sockets.clear();
  }

  Future<void> _bindSocket(
    InternetAddress bindAddr,
    String key, {
    String? ifaceName,
    String? label,
    required void Function(Datagram) onReceive,
  }) async {
    try {
      final socket = await RawDatagramSocket.bind(
        bindAddr,
        port,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket.receive();
        if (dg != null) onReceive(dg);
      });
      _sockets[key] = socket;
      final desc = label ?? (ifaceName != null ? '$ifaceName ($key)' : key);
      logInfo('UdpBroadcastTransport: socket bound on $desc');
    } catch (e) {
      logError('UdpBroadcastTransport: failed to bind $key', error: e);
    }
  }

  /// Эвристика /24: `192.168.1.25` → `192.168.1.255`.
  String? _subnetBroadcast(String ipv4) {
    final parts = ipv4.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }
}
