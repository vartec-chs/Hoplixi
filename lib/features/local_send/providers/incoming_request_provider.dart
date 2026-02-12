import 'package:hoplixi/features/local_send/models/transfer_request.dart';
import 'package:riverpod/riverpod.dart';

/// Провайдер для входящего запроса на передачу.
///
/// Устанавливается signaling-сервером при получении
/// `POST /api/prepare`. UI следит за этим провайдером
/// и показывает диалог подтверждения.
final incomingRequestProvider =
    NotifierProvider<IncomingRequestNotifier, TransferRequest?>(
      IncomingRequestNotifier.new,
    );

class IncomingRequestNotifier extends Notifier<TransferRequest?> {
  @override
  TransferRequest? build() => null;

  /// Устанавливает входящий запрос.
  void setRequest(TransferRequest? request) {
    state = request;
  }

  /// Очищает запрос.
  void clear() {
    state = null;
  }
}
