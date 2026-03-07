import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/services/device_registry.dart';
import 'package:hoplixi/features/local_send/services/discovery_status.dart';
import 'package:hoplixi/features/local_send/services/network_interface_cache.dart';
import 'package:hoplixi/features/local_send/services/udp_broadcast_transport.dart';
import 'package:mdns_dart/mdns_dart.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const String kServiceType = '_hoplixi._tcp';

class DiscoveryService {
  final _ifaceCache = NetworkInterfaceCache();
  late final _transport = UdpBroadcastTransport(ifaceCache: _ifaceCache);
  final _registry = DeviceRegistry();

  MDNSServer? _server;
  Timer? _discoveryTimer;
  Timer? _broadcastSendTimer;

  NetworkInterface? _activeInterface;

  DeviceInfo? _lastSelfInfo;
  String? _selfId;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectivityDebounceTimer;

  final _statusController = StreamController<DiscoveryStatus>.broadcast(
    sync: true,
  );
  DiscoveryStatus _status = DiscoveryStatus.stopped;

  Stream<List<DeviceInfo>> get devicesStream => _registry.stream;

  List<DeviceInfo> get devices => _registry.snapshot;

  Stream<DiscoveryStatus> get statusStream => _statusController.stream;

  DiscoveryStatus get status => _status;

  void _setStatus(DiscoveryStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  Future<String> getLocalIp({String? forcedIp}) async {
    if (forcedIp != null && forcedIp.isNotEmpty) return forcedIp;

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final status = await Permission.locationWhenInUse.request();
        if (status.isGranted) {
          final ip = await NetworkInfo().getWifiIP();
          if (ip != null && ip.isNotEmpty) return ip;
        }
      } catch (_) {}
    }

    final interfaces = await _ifaceCache.list();
    NetworkInterface? best;
    int bestScore = 999;
    for (final iface in interfaces) {
      final score = interfaceScore(iface.name.toLowerCase());
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

  // ---------------------------------------------------------------------------
  // mDNS helpers
  // ---------------------------------------------------------------------------

  String _toHostname(String name) {
    var result = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (result.isEmpty) result = 'device';
    if (result.length > 63) {
      result = result.substring(0, 63).replaceAll(RegExp(r'-+$'), '');
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // UDP broadcast
  // ---------------------------------------------------------------------------

  void _handleBroadcast(Datagram datagram) {
    try {
      final map =
          jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      final id = map['id'] as String?;
      if (id == null || id == _selfId) return;
      final signalingPort = (map['signalingPort'] as num?)?.toInt();
      if (signalingPort == null || signalingPort == 0) return;
      _registry.upsert(
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

  void _startBroadcastSender(DeviceInfo selfInfo) {
    _broadcastSendTimer?.cancel();
    _broadcastSendTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendBroadcastAnnounce(selfInfo),
    );
    _sendBroadcastAnnounce(selfInfo);
  }

  void _sendBroadcastAnnounce(DeviceInfo selfInfo) {
    final payload = utf8.encode(
      jsonEncode({
        'id': selfInfo.id,
        'name': selfInfo.name,
        'platform': selfInfo.platform,
        'signalingPort': selfInfo.signalingPort,
      }),
    );
    _transport.send(payload);
  }

  Future<void> startAdvertising(DeviceInfo selfInfo) async {
    _lastSelfInfo = selfInfo;

    await _stopMdns();

    try {
      final ip = InternetAddress(selfInfo.ip);
      _activeInterface = await _ifaceCache.findByIp(selfInfo.ip);
      if (_activeInterface != null) {
        logInfo(
          'DiscoveryService: mDNS on '
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
      _startBroadcastSender(selfInfo);
      _setStatus(DiscoveryStatus.running);
      logInfo('DiscoveryService: advertising started');
    } catch (e) {
      logError('DiscoveryService: failed to start advertising', error: e);
    }
  }

  Future<void> startDiscovery(String selfId) async {
    _setStatus(DiscoveryStatus.starting);
    _selfId = selfId;

    _discoveryTimer?.cancel();
    _discoveryTimer = null;

    await _transport.start(onReceive: _handleBroadcast);
    _subscribeConnectivity();

    await _performDiscovery(selfId);

    _discoveryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _performDiscovery(selfId),
    );

    logInfo('DiscoveryService: discovery started');
  }

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
        if (device == null || device.id == selfId) continue;
        _registry.upsert(device);
      }
    } catch (e) {
      logError('DiscoveryService: discovery scan error', error: e);
    }
  }

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

  Future<void> _stopMdns() async {
    _broadcastSendTimer?.cancel();
    _broadcastSendTimer = null;
    await _server?.stop();
    _server = null;
  }

  Future<void> _stopServer() async {
    _connectivityDebounceTimer?.cancel();
    _connectivityDebounceTimer = null;
    await _stopMdns();
    _transport.stop();
  }

  void _subscribeConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.every((r) => r == ConnectivityResult.none)) return;
      _connectivityDebounceTimer?.cancel();
      _connectivityDebounceTimer = Timer(
        const Duration(milliseconds: 1500),
        _restartAll,
      );
    });
  }

  Future<void> _restartAll() async {
    final selfInfo = _lastSelfInfo;
    final selfId = _selfId;
    if (selfInfo == null || selfId == null) return;

    logInfo('DiscoveryService: network changed, restarting...');
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _ifaceCache.invalidate();
    await _stopServer();

    await startDiscovery(selfId);
    await startAdvertising(selfInfo);
  }

  Future<void> dispose() async {
    _setStatus(DiscoveryStatus.stopped);
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    await _stopServer();
    _registry.dispose();
    if (!_statusController.isClosed) _statusController.close();
    logInfo('DiscoveryService: disposed');
  }
}
