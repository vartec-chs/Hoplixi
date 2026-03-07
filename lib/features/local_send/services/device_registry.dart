import 'dart:async';

import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';

/// TTL устройства: если не видели дольше — удаляем из реестра.
const Duration kDeviceTtl = Duration(seconds: 10);

/// Реестр обнаруженных устройств с TTL-очисткой и реактивным стримом.
///
/// Каждое изменение реестра публикует обновлённый [List<DeviceInfo>]
/// в [stream]. Broadcast-стрим без буферизации для новых подписчиков;
/// доставка асинхронная (через микротаск) — это безопасно при
/// мобильных lifecycle-событиях, когда dispose может прийти
/// во время обработки события.
class DeviceRegistry {
  final _devices = <String, DeviceInfo>{};
  bool _isDisposed = false;

  // broadcast → не буферизует events для новых подписчиков.
  // sync: false (по умолчанию) → доставка через микротаск,
  // что исключает «Bad state: Cannot add event after closing»
  // при мобильных lifecycle-событиях.
  final _controller = StreamController<List<DeviceInfo>>.broadcast();

  Timer? _cleanupTimer;

  DeviceRegistry() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _removeExpired(),
    );
  }

  /// Стрим обновлённого списка при каждом изменении реестра.
  Stream<List<DeviceInfo>> get stream => _controller.stream;

  /// Текущий снимок списка (неизменяемый).
  List<DeviceInfo> get snapshot => List.unmodifiable(_devices.values.toList());

  /// Добавляет или обновляет устройство, фиксируя текущее время в [lastSeen].
  void upsert(DeviceInfo device) {
    if (_isDisposed) return;
    final updated = device.copyWith(
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
    final isNew = !_devices.containsKey(device.id);
    _devices[device.id] = updated;
    if (isNew) {
      logInfo('DeviceRegistry: new device → ${device.name} @ ${device.ip}');
    }
    _emit();
  }

  void _removeExpired() {
    if (_isDisposed) return;
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - kDeviceTtl.inMilliseconds;
    final before = _devices.length;
    _devices.removeWhere((_, d) => d.lastSeen < cutoff);
    if (_devices.length != before) {
      logInfo(
        'DeviceRegistry: removed ${before - _devices.length} stale device(s)',
      );
      _emit();
    }
  }

  void _emit() {
    if (_controller.isClosed) return;
    try {
      _controller.add(snapshot);
    } catch (_) {
      // Контроллер закрылся между проверкой и add() — игнорируем.
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    if (!_controller.isClosed) _controller.close();
  }
}
