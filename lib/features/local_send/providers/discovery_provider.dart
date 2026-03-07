import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/providers/discovery_settings_provider.dart';
import 'package:hoplixi/features/local_send/services/discovery_service.dart';
import 'package:uuid/uuid.dart';

/// Имя текущего устройства.
/// Если пользователь задал кастомное имя — использует его,
/// иначе — hostname ОС.
/// На Android/iOS `Platform.localHostname` часто возвращает "localhost",
/// поэтому добавлены платформенные fallback-значения.
final localDeviceName = Provider<String>((ref) {
  final settings = ref.watch(discoverySettingsProvider);
  if (settings.value?.customDeviceName != null) {
    return settings.value!.customDeviceName!;
  }
  final hostname = Platform.localHostname;
  if (hostname.isEmpty || hostname.toLowerCase() == 'localhost') {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iPhone';
    return 'Device';
  }
  return hostname;
});

/// Платформа текущего устройства.
final localDevicePlatform = Provider<String>((_) {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  if (Platform.isWindows) return 'windows';
  return 'unknown';
});

/// ID текущего устройства (из UUID при старте).
final localDeviceIdProvider = Provider<String>((_) => const Uuid().v4());

/// Провайдер списка обнаруженных устройств в локальной сети.
///
/// При инициализации запускает UDP broadcast + listener.
/// Автоматически удаляет устройства, которые не отвечали
/// более 10 секунд.
final discoveryProvider =
    AsyncNotifierProvider.autoDispose<DiscoveryNotifier, List<DeviceInfo>>(
      DiscoveryNotifier.new,
    );

class DiscoveryNotifier extends AsyncNotifier<List<DeviceInfo>> {
  DiscoveryService? _service;
  StreamSubscription<dynamic>? _subscription;
  Timer? _cleanupTimer;

  /// Порт signaling-сервера (устанавливается провайдером
  /// передачи после старта сервера).
  int _signalingPort = 0;

  /// Устанавливает порт signaling-сервера для broadcast.
  void setSignalingPort(int port) {
    _signalingPort = port;
    _restartBroadcast();
  }

  @override
  Future<List<DeviceInfo>> build() async {
    ref.onDispose(_dispose);

    _service = DiscoveryService();

    final selfId = ref.read(localDeviceIdProvider);

    // ВАЖНО: ref.listen должен быть до первого await, иначе
    // подписка может не установиться корректно в Riverpod.
    ref.listen<AsyncValue<DiscoverySettings>>(discoverySettingsProvider, (
      _,
      next,
    ) {
      if (next.hasValue) _restartBroadcast();
    });

    // Запускаем сканирование (занимает время из-за mDNS timeout).
    await _service!.startDiscovery(selfId);

    // Подписываемся на стрим устройств.
    _subscription = _service!.devicesStream.listen((dynamic data) {
      if (data is DeviceInfo) {
        _onDeviceFound(data);
      }
    });

    // Периодическая очистка неактивных устройств (10с).
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cleanupStaleDevices(),
    );

    return [];
  }

  /// Запускает (или перезапускает) broadcast с текущим портом.
  ///
  /// Если порт ещё не установлен — broadcast не запускается.
  Future<void> _restartBroadcast() async {
    if (_signalingPort == 0) return;

    final settings = ref.read(discoverySettingsProvider).value;
    final ip =
        await _service?.getLocalIp(forcedIp: settings?.forcedIp) ?? '0.0.0.0';
    final name = ref.read(localDeviceName);
    final platform = ref.read(localDevicePlatform);

    final selfInfo = DeviceInfo(
      id: ref.read(localDeviceIdProvider),
      name: name,
      ip: ip,
      signalingPort: _signalingPort,
      platform: platform,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await _service?.startAdvertising(selfInfo);
    } catch (e) {
      logError('Discovery broadcast restart failed', error: e);
    }
  }

  void _onDeviceFound(DeviceInfo device) {
    final currentList = state.value ?? [];

    // Обновляем lastSeen или добавляем новое устройство.
    final updated = device.copyWith(
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );

    final existingIndex = currentList.indexWhere((d) => d.id == device.id);

    List<DeviceInfo> newList;
    if (existingIndex >= 0) {
      newList = [...currentList];
      newList[existingIndex] = updated;
    } else {
      newList = [...currentList, updated];
      logInfo('Discovery: new device found: ${device.name} @ ${device.ip}');
    }

    state = AsyncData(newList);
  }

  void _cleanupStaleDevices() {
    final currentList = state.value ?? [];
    if (currentList.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    const timeout = 10000; // 10 секунд.

    final filtered = currentList.where((d) {
      return now - d.lastSeen < timeout;
    }).toList();

    if (filtered.length != currentList.length) {
      state = AsyncData(filtered);
    }
  }

  Future<void> _dispose() async {
    _subscription?.cancel();
    _cleanupTimer?.cancel();
    await _service?.dispose();
  }
}
