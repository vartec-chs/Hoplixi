import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/local_send/models/transfer_request.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Статус ответа на prepare-запрос.
enum PrepareStatus { pending, accepted, rejected }

/// WebSocket signaling-сервер для WebRTC handshake
/// и подтверждения передачи файлов.
///
/// Каждое устройство запускает свой signaling-сервер.
/// Когда отправитель хочет передать файлы, он подключается
/// по WebSocket и обменивается JSON-сообщениями.
///
/// Протокол сообщений (JSON с полем `type`):
/// - `prepare` — запрос на передачу
/// - `prepare_status` — ответ со статусом
/// - `offer` — SDP offer
/// - `answer` — SDP answer
/// - `ice` — ICE candidate
/// - `cancel` — отмена передачи
class SignalingServer {
  HttpServer? _server;
  WebSocketChannel? _activeChannel;
  StreamSubscription<dynamic>? _channelSubscription;

  /// Порт, на котором запущен сервер.
  int get port => _server?.port ?? 0;

  // ── Внутреннее состояние ──

  PrepareStatus _prepareStatus = PrepareStatus.pending;
  TransferRequest? _currentRequest;

  final List<String> _localIceCandidates = [];
  final List<String> _remoteIceCandidates = [];

  // ── Колбэки ──

  /// Вызывается при получении prepare-запроса.
  /// UI должен показать диалог accept/reject.
  void Function(TransferRequest request)? onPrepareRequest;

  /// Вызывается при получении SDP offer.
  void Function(String sdp)? onOfferReceived;

  /// Вызывается при получении ICE candidate.
  void Function(String candidate)? onIceCandidateReceived;

  /// Подтверждает входящий prepare-запрос.
  void acceptTransfer() {
    _prepareStatus = PrepareStatus.accepted;
    _sendStatusUpdate();
  }

  /// Отклоняет входящий prepare-запрос.
  void rejectTransfer() {
    _prepareStatus = PrepareStatus.rejected;
    _sendStatusUpdate();
  }

  /// Устанавливает SDP answer для отдачи отправителю.
  void setLocalAnswer(String answer) {
    _sendMessage({'type': 'answer', 'data': answer});
  }

  /// Добавляет локальный ICE candidate для отдачи.
  void addLocalIceCandidate(String candidate) {
    _localIceCandidates.add(candidate);
    _sendMessage({'type': 'ice', 'data': candidate});
  }

  /// Запускает HTTP-сервер с WebSocket-upgrade на свободном порту.
  Future<int> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

    logInfo('SignalingServer: started on port ${_server!.port}');

    _server!.listen(_handleHttpRequest);

    return _server!.port;
  }

  /// Обрабатывает входящий HTTP-запрос и выполняет
  /// WebSocket-upgrade.
  Future<void> _handleHttpRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('WebSocket upgrade required');
      await request.response.close();
      return;
    }

    try {
      // Закрываем предыдущее подключение, если есть.
      await _disconnectClient();

      final socket = await WebSocketTransformer.upgrade(request);
      _activeChannel = IOWebSocketChannel(socket);

      logInfo('SignalingServer: client connected');

      _channelSubscription = _activeChannel!.stream.listen(
        _handleMessage,
        onDone: () {
          logInfo('SignalingServer: client disconnected');
          _activeChannel = null;
          _channelSubscription = null;
        },
        onError: (Object error) {
          logError('SignalingServer: WebSocket error', error: error);
          _activeChannel = null;
          _channelSubscription = null;
        },
      );
    } catch (e, s) {
      logError('SignalingServer: upgrade failed', error: e, stackTrace: s);
    }
  }

  /// Обрабатывает входящее WebSocket-сообщение.
  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      switch (type) {
        case 'prepare':
          _handlePrepare(message);
        case 'offer':
          _handleOffer(message);
        case 'ice':
          _handleIce(message);
        case 'cancel':
          _handleCancel();
        default:
          logInfo('SignalingServer: unknown message type: $type');
      }
    } catch (e, s) {
      logError(
        'SignalingServer: message handling error',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Обрабатывает `prepare` — запрос на передачу.
  void _handlePrepare(Map<String, dynamic> message) {
    final data = message['data'] as Map<String, dynamic>?;
    if (data == null) return;

    _currentRequest = TransferRequest.fromJson(data);
    _prepareStatus = PrepareStatus.pending;

    // Сбрасываем WebRTC-состояние.
    _localIceCandidates.clear();
    _remoteIceCandidates.clear();

    onPrepareRequest?.call(_currentRequest!);

    _sendMessage({
      'type': 'prepare_status',
      'data': {'status': 'pending'},
    });
  }

  /// Обрабатывает `offer` — SDP offer от отправителя.
  void _handleOffer(Map<String, dynamic> message) {
    final data = message['data'] as String?;
    if (data == null) return;

    onOfferReceived?.call(data);

    _sendMessage({
      'type': 'offer_ack',
      'data': {'status': 'ok'},
    });
  }

  /// Обрабатывает `ice` — ICE candidate от отправителя.
  void _handleIce(Map<String, dynamic> message) {
    final data = message['data'] as String?;
    if (data == null) return;

    _remoteIceCandidates.add(data);
    onIceCandidateReceived?.call(data);
  }

  /// Обрабатывает `cancel` — отмена передачи.
  void _handleCancel() {
    _prepareStatus = PrepareStatus.rejected;
    _currentRequest = null;

    _sendMessage({
      'type': 'cancel_ack',
      'data': {'status': 'cancelled'},
    });
  }

  /// Отправляет обновлённый статус prepare-запроса клиенту.
  void _sendStatusUpdate() {
    _sendMessage({
      'type': 'prepare_status',
      'data': {'status': _prepareStatus.name},
    });
  }

  /// Отправляет JSON-сообщение активному клиенту.
  void _sendMessage(Map<String, dynamic> message) {
    try {
      _activeChannel?.sink.add(jsonEncode(message));
    } catch (e) {
      logError('SignalingServer: send error', error: e);
    }
  }

  /// Отключает текущего клиента.
  Future<void> _disconnectClient() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;

    try {
      await _activeChannel?.sink.close();
    } catch (_) {
      // Канал уже закрыт — игнорируем.
    }
    _activeChannel = null;
  }

  /// Полный сброс состояния сервера.
  Future<void> reset() async {
    await _disconnectClient();

    _prepareStatus = PrepareStatus.pending;
    _currentRequest = null;
    _localIceCandidates.clear();
    _remoteIceCandidates.clear();
  }

  /// Останавливает сервер.
  Future<void> stop() async {
    await _disconnectClient();

    await _server?.close(force: true);
    _server = null;

    _prepareStatus = PrepareStatus.pending;
    _currentRequest = null;
    _localIceCandidates.clear();
    _remoteIceCandidates.clear();

    logInfo('SignalingServer: stopped');
  }
}
