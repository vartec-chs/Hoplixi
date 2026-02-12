import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/local_send/models/transfer_request.dart';

/// Статус ответа на prepare-запрос.
enum PrepareStatus { pending, accepted, rejected }

/// HTTP signaling-сервер для WebRTC handshake
/// и подтверждения передачи файлов.
///
/// Каждое устройство запускает свой signaling-сервер.
/// Когда отправитель хочет передать файлы, он шлёт prepare-запрос
/// на signaling-порт получателя.
class SignalingServer {
  HttpServer? _server;

  /// Порт, на котором запущен сервер.
  int get port => _server?.port ?? 0;

  // ── Внутреннее состояние ──

  PrepareStatus _prepareStatus = PrepareStatus.pending;
  TransferRequest? _currentRequest;

  String? _receivedOffer;
  String? _localAnswer;
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
  }

  /// Отклоняет входящий prepare-запрос.
  void rejectTransfer() {
    _prepareStatus = PrepareStatus.rejected;
  }

  /// Устанавливает SDP answer для отдачи отправителю.
  void setLocalAnswer(String answer) {
    _localAnswer = answer;
  }

  /// Добавляет локальный ICE candidate для отдачи.
  void addLocalIceCandidate(String candidate) {
    _localIceCandidates.add(candidate);
  }

  /// Запускает HTTP signaling-сервер на свободном порту.
  Future<int> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

    logInfo('SignalingServer: started on port ${_server!.port}');

    _server!.listen(_handleRequest);

    return _server!.port;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    try {
      // CORS headers для простоты.
      request.response.headers.add('Access-Control-Allow-Origin', '*');

      if (method == 'POST' && path == '/api/prepare') {
        await _handlePrepare(request);
      } else if (method == 'GET' && path == '/api/prepare/status') {
        _handlePrepareStatus(request);
      } else if (method == 'POST' && path == '/api/offer') {
        await _handleOffer(request);
      } else if (method == 'GET' && path == '/api/answer') {
        _handleAnswer(request);
      } else if (method == 'POST' && path == '/api/ice') {
        await _handleIcePost(request);
      } else if (method == 'GET' && path == '/api/ice') {
        _handleIceGet(request);
      } else if (method == 'POST' && path == '/api/cancel') {
        _handleCancel(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not Found');
      }
    } catch (e, s) {
      logError('SignalingServer error', error: e, stackTrace: s);
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal Server Error');
    }

    await request.response.close();
  }

  /// `POST /api/prepare` — входящий запрос на передачу.
  Future<void> _handlePrepare(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    _currentRequest = TransferRequest.fromJson(json);
    _prepareStatus = PrepareStatus.pending;

    // Сбрасываем WebRTC-состояние.
    _receivedOffer = null;
    _localAnswer = null;
    _localIceCandidates.clear();
    _remoteIceCandidates.clear();

    onPrepareRequest?.call(_currentRequest!);

    request.response.statusCode = HttpStatus.ok;
    request.response.write('{"status":"pending"}');
  }

  /// `GET /api/prepare/status` — polling статуса.
  void _handlePrepareStatus(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.write('{"status":"${_prepareStatus.name}"}');
  }

  /// `POST /api/offer` — SDP offer от отправителя.
  Future<void> _handleOffer(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    _receivedOffer = body;

    onOfferReceived?.call(body);

    request.response.statusCode = HttpStatus.ok;
    request.response.write('{"status":"ok"}');
  }

  /// `GET /api/answer` — SDP answer для отправителя.
  void _handleAnswer(HttpRequest request) {
    if (_localAnswer == null) {
      request.response.statusCode = HttpStatus.ok;
      request.response.write('{"status":"pending"}');
      return;
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.write(_localAnswer);
  }

  /// `POST /api/ice` — ICE candidate от отправителя.
  Future<void> _handleIcePost(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    _remoteIceCandidates.add(body);

    onIceCandidateReceived?.call(body);

    request.response.statusCode = HttpStatus.ok;
    request.response.write('{"status":"ok"}');
  }

  /// `GET /api/ice` — локальные ICE candidates.
  void _handleIceGet(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.write(jsonEncode(_localIceCandidates));
  }

  /// `POST /api/cancel` — отмена передачи.
  void _handleCancel(HttpRequest request) {
    _prepareStatus = PrepareStatus.rejected;
    _currentRequest = null;

    request.response.statusCode = HttpStatus.ok;
    request.response.write('{"status":"cancelled"}');
  }

  /// Полный сброс состояния сервера.
  void reset() {
    _prepareStatus = PrepareStatus.pending;
    _currentRequest = null;
    _receivedOffer = null;
    _localAnswer = null;
    _localIceCandidates.clear();
    _remoteIceCandidates.clear();
  }

  /// Останавливает сервер.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    reset();
    logInfo('SignalingServer: stopped');
  }
}
