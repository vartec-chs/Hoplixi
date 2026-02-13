import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';

/// Порт для UDP broadcast обнаружения устройств.
const int kDiscoveryPort = 37020;

/// Сервис обнаружения устройств в локальной сети
/// через UDP broadcast.
class DiscoveryService {
  RawDatagramSocket? _senderSocket;
  RawDatagramSocket? _listenerSocket;
  Timer? _broadcastTimer;

  final _devicesController = StreamController<DeviceInfo>.broadcast();

  /// Стрим найденных устройств.
  Stream<DeviceInfo> get devicesStream => _devicesController.stream;

  /// Получает локальный IPv4-адрес устройства.
  Future<String> getLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }

    return '0.0.0.0';
  }

  /// Начинает периодическую рассылку broadcast
  /// с информацией об этом устройстве.
  Future<void> startBroadcast(DeviceInfo selfInfo) async {
    _senderSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _senderSocket!.broadcastEnabled = true;

    final broadcastAddr = InternetAddress('255.255.255.255');

    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      try {
        final data = utf8.encode(jsonEncode(selfInfo.toJson()));
        _senderSocket?.send(data, broadcastAddr, kDiscoveryPort);
      } catch (e) {
        logError('DiscoveryService broadcast error', error: e);
      }
    });

    logInfo('DiscoveryService: broadcast started');
  }

  /// Запускает слушатель broadcast-пакетов от других устройств.
  ///
  /// [selfId] — ID текущего устройства (чтобы игнорировать
  /// свои собственные пакеты).
  Future<void> startListener(String selfId) async {
    _listenerSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      kDiscoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    _listenerSocket!.broadcastEnabled = true;

    _listenerSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;

      final datagram = _listenerSocket?.receive();
      if (datagram == null) return;

      try {
        final json = jsonDecode(utf8.decode(datagram.data));
        final device = DeviceInfo.fromJson(json as Map<String, dynamic>);

        // Игнорируем свои пакеты.
        if (device.id == selfId) return;

        _devicesController.add(device);
      } catch (_) {
        // Свои broadcast-пакеты или невалидные данные —
        // нормальное явление, не логируем.
      }
    });

    logInfo('DiscoveryService: listener started on port $kDiscoveryPort');
  }

  /// Останавливает broadcast и listener.
  void dispose() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _senderSocket?.close();
    _senderSocket = null;

    _listenerSocket?.close();
    _listenerSocket = null;

    _devicesController.close();

    logInfo('DiscoveryService: disposed');
  }
}
