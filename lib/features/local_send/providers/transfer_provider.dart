import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/transfer_request.dart';
import 'package:hoplixi/features/local_send/models/transfer_state.dart';
import 'package:hoplixi/features/local_send/providers/discovery_provider.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/services/signaling_server.dart';
import 'package:hoplixi/features/local_send/services/webrtc_transfer_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Провайдер состояния передачи.
final transferProvider = NotifierProvider<TransferNotifier, TransferState>(
  TransferNotifier.new,
);

/// Оркестрирует signaling-сервер, WebRTC-соединение
/// и процесс передачи файлов/текста.
class TransferNotifier extends Notifier<TransferState> {
  SignalingServer? _signalingServer;
  WebRtcTransferService? _webrtc;

  /// Общий HTTP-клиент с увеличенными таймаутами.
  HttpClient? _httpClient;

  /// Максимальное количество повторных попыток HTTP-запроса.
  static const int _maxRetries = 3;

  /// Базовая задержка между повторными попытками.
  static const Duration _retryDelay = Duration(seconds: 1);

  // Для приёма файлов.
  IOSink? _currentFileSink;
  String? _currentFileName;
  int _currentFileSize = 0;
  int _currentFileReceived = 0;

  @override
  TransferState build() {
    ref.onDispose(_dispose);
    _startSignalingServer();
    return const TransferState.idle();
  }

  /// Запускает signaling-сервер и регистрирует порт
  /// в discovery-провайдере.
  Future<void> _startSignalingServer() async {
    _signalingServer = SignalingServer();
    final port = await _signalingServer!.start();

    // Сообщаем discovery-провайдеру наш порт.
    ref.read(discoveryProvider.notifier).setSignalingPort(port);

    // Настраиваем колбэк для входящих запросов.
    _signalingServer!.onPrepareRequest = _onIncomingPrepare;
    _signalingServer!.onOfferReceived = _onOfferReceived;

    logInfo('TransferNotifier: signaling on port $port');
  }

  // ══════════════════════════════════════════════
  //  Отправитель (sender flow)
  // ══════════════════════════════════════════════

  /// Отправляет запрос на передачу файлов/текста
  /// выбранному устройству.
  Future<void> sendToDevice({
    required DeviceInfo target,
    required List<File> files,
    String? text,
  }) async {
    state = const TransferState.preparing();

    try {
      _httpClient = _createHttpClient();

      final selfId = ref.read(localDeviceIdProvider);
      final selfIp = await _getSelfIp();

      final fileMetadataList = <FileMetadata>[];
      for (final file in files) {
        final name = p.basename(file.path);
        final size = await file.length();
        final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
        fileMetadataList.add(
          FileMetadata(name: name, size: size, mimeType: mime),
        );
      }

      final request = TransferRequest(
        senderDevice: DeviceInfo(
          id: selfId,
          name: Platform.localHostname,
          ip: selfIp,
          signalingPort: _signalingServer?.port ?? 0,
          platform: _getDevicePlatform(),
          lastSeen: DateTime.now().millisecondsSinceEpoch,
        ),
        files: fileMetadataList,
        text: text,
      );

      // Шлём prepare-запрос на signaling-сервер получателя.
      final prepareResponse = await _httpPost(
        target,
        '/api/prepare',
        jsonEncode(request.toJson()),
      );

      if (prepareResponse.statusCode != HttpStatus.ok) {
        state = const TransferState.error(
          message: 'Failed to send prepare request',
        );
        return;
      }

      state = const TransferState.waitingApproval();

      // Polling статуса подтверждения.
      final accepted = await _pollPrepareStatus(target);

      if (!accepted) {
        state = const TransferState.rejected();
        return;
      }

      // Подтверждено — запускаем WebRTC handshake.
      state = const TransferState.connecting();

      _webrtc = WebRtcTransferService();
      _setupSenderCallbacks(files, text);

      // Создаём offer.
      final offerJson = await _webrtc!.createOffer();

      // Отправляем offer.
      await _httpPost(target, '/api/offer', offerJson);

      // Отправляем ICE candidates.
      _webrtc!.onLocalIceCandidate = (candidateJson) {
        _httpPost(target, '/api/ice', candidateJson);
      };

      // Получаем answer.
      final answerJson = await _pollForAnswer(target);
      if (answerJson == null) {
        state = const TransferState.error(
          message: 'Failed to get answer from receiver',
        );
        return;
      }
      await _webrtc!.handleAnswer(answerJson);

      // Получаем ICE candidates получателя.
      await _fetchRemoteIceCandidates(target);

      // Ждём соединения — onConnected вызовет _startSending.
    } on SocketException catch (e, s) {
      logError('TransferNotifier.sendToDevice', error: e, stackTrace: s);
      state = TransferState.error(
        message:
            'Не удалось подключиться к устройству. '
            'Убедитесь, что оба устройства в одной сети. '
            '(${e.message})',
      );
    } catch (e, s) {
      logError('TransferNotifier.sendToDevice', error: e, stackTrace: s);
      state = TransferState.error(message: e.toString());
    }
  }

  void _setupSenderCallbacks(List<File> files, String? text) {
    _webrtc!.onConnected = () async {
      logInfo('WebRTC connected — starting file transfer');

      // Даём время DataChannel полностью открыться.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await _startSending(files, text);
    };

    _webrtc!.onError = (error) {
      state = TransferState.error(message: error);
    };

    _webrtc!.onCancelled = () {
      state = const TransferState.cancelled();
    };
  }

  Future<void> _startSending(List<File> files, String? text) async {
    // Сначала отправляем текст, если есть.
    if (text != null && text.isNotEmpty) {
      await _webrtc!.sendText(text);
    }

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = p.basename(file.path);

      state = TransferState.transferring(
        progress: 0,
        currentFile: fileName,
        currentIndex: i,
        totalFiles: files.length,
      );

      _webrtc!.onProgress = (sent, total) {
        state = TransferState.transferring(
          progress: sent / total,
          currentFile: fileName,
          currentIndex: i,
          totalFiles: files.length,
        );
      };

      await _webrtc!.sendFile(file);
    }

    _webrtc!.sendTransferComplete();
    state = const TransferState.completed();
  }

  // ══════════════════════════════════════════════
  //  Получатель (receiver flow)
  // ══════════════════════════════════════════════

  void _onIncomingPrepare(TransferRequest request) {
    // Показываем запрос в UI через provider.
    ref.read(incomingRequestProvider.notifier).setRequest(request);
    logInfo(
      'Incoming transfer from ${request.senderDevice.name}: '
      '${request.files.length} files',
    );
  }

  /// Принимает входящий запрос.
  Future<void> acceptIncomingTransfer() async {
    _signalingServer?.acceptTransfer();
    state = const TransferState.connecting();

    // Настраиваем WebRTC для приёма.
    _webrtc = WebRtcTransferService();
    _setupReceiverCallbacks();

    // Ждём offer от отправителя.
    _signalingServer!.onOfferReceived = _onOfferReceived;

    // ICE candidates.
    _webrtc!.onLocalIceCandidate = (candidateJson) {
      _signalingServer?.addLocalIceCandidate(candidateJson);
    };

    _signalingServer!.onIceCandidateReceived = (candidateJson) {
      _webrtc?.addIceCandidate(candidateJson);
    };
  }

  /// Отклоняет входящий запрос.
  void rejectIncomingTransfer() {
    _signalingServer?.rejectTransfer();
    ref.read(incomingRequestProvider.notifier).clear();
    state = const TransferState.idle();
  }

  Future<void> _onOfferReceived(String offerJson) async {
    if (_webrtc == null) return;

    try {
      final answerJson = await _webrtc!.handleOffer(offerJson);
      _signalingServer?.setLocalAnswer(answerJson);
    } catch (e, s) {
      logError('_onOfferReceived error', error: e, stackTrace: s);
      state = TransferState.error(message: e.toString());
    }
  }

  void _setupReceiverCallbacks() {
    final request = ref.read(incomingRequestProvider);

    _webrtc!.onConnected = () {
      logInfo('WebRTC connected as receiver — ready');
    };

    _webrtc!.onFileStart = (fileName, fileSize) async {
      _currentFileName = fileName;
      _currentFileSize = fileSize;
      _currentFileReceived = 0;

      final downloadsDir = await _getDownloadsDir();
      final filePath = p.join(downloadsDir.path, fileName);
      final file = File(filePath);
      _currentFileSink = file.openWrite();

      final totalFiles = request?.files.length ?? 1;
      final index = request?.files.indexWhere((f) => f.name == fileName) ?? 0;

      state = TransferState.transferring(
        progress: 0,
        currentFile: fileName,
        currentIndex: index >= 0 ? index : 0,
        totalFiles: totalFiles,
      );
    };

    _webrtc!.onFileChunkReceived = (chunk) {
      _currentFileSink?.add(chunk);
      _currentFileReceived += chunk.length;

      if (_currentFileSize > 0) {
        final totalFiles = ref.read(incomingRequestProvider)?.files.length ?? 1;
        final index =
            ref
                .read(incomingRequestProvider)
                ?.files
                .indexWhere((f) => f.name == _currentFileName) ??
            0;

        state = TransferState.transferring(
          progress: _currentFileReceived / _currentFileSize,
          currentFile: _currentFileName ?? '',
          currentIndex: index >= 0 ? index : 0,
          totalFiles: totalFiles,
        );
      }
    };

    _webrtc!.onFileEnd = (fileName) async {
      await _currentFileSink?.flush();
      await _currentFileSink?.close();
      _currentFileSink = null;
      logInfo('File received: $fileName');
    };

    _webrtc!.onTextReceived = (text) {
      logInfo('Text received: $text');
    };

    _webrtc!.onTransferComplete = () {
      state = const TransferState.completed();
      // Не очищаем incomingRequestProvider здесь —
      // диалог покажет "Получено!" с кнопкой "Закрыть".
    };

    _webrtc!.onCancelled = () {
      state = const TransferState.cancelled();
      ref.read(incomingRequestProvider.notifier).clear();
    };

    _webrtc!.onError = (error) {
      state = TransferState.error(message: error);
    };
  }

  // ══════════════════════════════════════════════
  //  Общее
  // ══════════════════════════════════════════════

  /// Сбрасывает состояние.
  Future<void> reset() async {
    await _webrtc?.dispose();
    _webrtc = null;

    _httpClient?.close(force: true);
    _httpClient = null;

    _currentFileSink?.close();
    _currentFileSink = null;
    _currentFileName = null;
    _currentFileSize = 0;
    _currentFileReceived = 0;

    _signalingServer?.reset();

    ref.read(incomingRequestProvider.notifier).clear();
    state = const TransferState.idle();
  }

  void _dispose() {
    _webrtc?.dispose();
    _signalingServer?.stop();
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  // ══════════════════════════════════════════════
  //  HTTP helpers
  // ══════════════════════════════════════════════

  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    client.idleTimeout = const Duration(seconds: 30);
    return client;
  }

  HttpClient get _client => _httpClient ??= _createHttpClient();

  /// Выполняет POST-запрос с повторными попытками.
  Future<HttpClientResponse> _httpPost(
    DeviceInfo target,
    String path,
    String body, {
    int retries = _maxRetries,
  }) async {
    final uri = Uri.parse('http://${target.ip}:${target.signalingPort}$path');

    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        final request = await _client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(body);
        return await request.close();
      } on SocketException catch (e) {
        logTrace(
          'HTTP POST $path attempt ${attempt + 1}/$retries '
          'failed: ${e.message}',
        );

        if (attempt == retries - 1) rethrow;

        await Future<void>.delayed(_retryDelay * (attempt + 1));
      }
    }

    // Недостижимо, но нужно для компилятора.
    throw StateError('Unreachable');
  }

  /// Выполняет GET-запрос (без retry, для polling).
  Future<String?> _httpGet(DeviceInfo target, String path) async {
    final uri = Uri.parse('http://${target.ip}:${target.signalingPort}$path');

    try {
      final request = await _client.getUrl(uri);
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
    } on SocketException catch (e) {
      logTrace('HTTP GET $path failed: ${e.message}');
      return null;
    }
  }

  /// Polling статуса подтверждения (макс. 60с).
  Future<bool> _pollPrepareStatus(DeviceInfo target) async {
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));

      try {
        final body = await _httpGet(target, '/api/prepare/status');
        if (body == null) continue;

        final json = jsonDecode(body) as Map<String, dynamic>;
        final status = json['status'] as String?;

        if (status == 'accepted') return true;
        if (status == 'rejected') return false;
      } catch (e) {
        logTrace('Polling prepare status error: $e');
      }
    }

    return false; // Timeout.
  }

  /// Polling SDP answer (макс. 30с).
  Future<String?> _pollForAnswer(DeviceInfo target) async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));

      try {
        final body = await _httpGet(target, '/api/answer');
        if (body == null) continue;

        final json = jsonDecode(body);
        if (json is Map && json.containsKey('sdp')) {
          return body;
        }
      } catch (e) {
        logTrace('Polling answer error: $e');
      }
    }

    return null;
  }

  /// Fetch remote ICE candidates.
  Future<void> _fetchRemoteIceCandidates(DeviceInfo target) async {
    try {
      final body = await _httpGet(target, '/api/ice');
      if (body == null) return;

      final candidates = jsonDecode(body) as List<dynamic>;
      for (final c in candidates) {
        await _webrtc?.addIceCandidate(c as String);
      }
    } catch (e) {
      logTrace('Fetch ICE candidates error: $e');
    }
  }

  Future<String> _getSelfIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }

    return '0.0.0.0';
  }

  String _getDevicePlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
  }

  Future<Directory> _getDownloadsDir() async {
    final dir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return dir;
  }
}
