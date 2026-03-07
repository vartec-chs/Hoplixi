import 'dart:async';

import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';

/// TTL устройства: если не видели дольше — удаляем из реестра.
const Duration kDeviceTtl = Duration(seconds: 10);

/// Реестр обнаруженных устройств с TTL-очисткой и реактивным стримом.
///
/// Каждое изменение реестра публикует обновлённый [List<DeviceInfo>]
/// в [stream]. Использует [StreamController.broadcast(sync: true)] —
/// события доставляются синхронно и не буферизуются, что исключает
/// накопление невычитанных событий при медленном потребителе.
class DeviceRegistry {
  final _devices = <String, DeviceInfo>{};

  // sync: true → немедленная доставка без async-очереди.
  // broadcast → не буферизует events для новых подписчиков.
  final _controller = StreamController<List<DeviceInfo>>.broadcast(sync: true);

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
    if (!_controller.isClosed) _controller.add(snapshot);
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    if (!_controller.isClosed) _controller.close();
  }
}
