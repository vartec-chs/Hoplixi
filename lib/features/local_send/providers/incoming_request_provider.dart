import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:riverpod/riverpod.dart';

/// Провайдер для входящего запроса на соединение.
///
/// Устанавливается signaling-сервером при получении
/// prepare-запроса. UI следит за этим провайдером
/// и показывает диалог подтверждения.
final incomingRequestProvider =
    NotifierProvider.autoDispose<IncomingRequestNotifier, DeviceInfo?>(
      IncomingRequestNotifier.new,
    );

class IncomingRequestNotifier extends Notifier<DeviceInfo?> {
  @override
  DeviceInfo? build() => null;

  /// Устанавливает входящий запрос.
  void setRequest(DeviceInfo? device) {
    state = device;
  }

  /// Очищает запрос.
  void clear() {
    state = null;
  }
}
