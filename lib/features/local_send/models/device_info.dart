import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';
part 'device_info.g.dart';

/// Информация об устройстве, обнаруженном в локальной сети.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    /// Уникальный идентификатор устройства (UUID).
    required String id,

    /// Имя устройства (например, "iPhone Ивана").
    required String name,

    /// IP-адрес в локальной сети.
    required String ip,

    /// Порт HTTP signaling-сервера.
    required int signalingPort,

    /// Платформа: android, ios, windows, macos, linux.
    required String platform,

    /// Время последнего обнаружения (мс от эпохи).
    required int lastSeen,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}
