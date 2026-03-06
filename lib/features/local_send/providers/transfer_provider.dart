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
import 'package:web_socket_channel/web_socket_channel.dart';

/// Провайдер состояния передачи.
final transferProvider = NotifierProvider<TransferNotifier, TransferState>(
  TransferNotifier.new,
);

/// Оркестрирует signaling-сервер, WebRTC-соединение
/// и процесс передачи файлов/текста.
class TransferNotifier extends Notifier<TransferState> {
  SignalingServer? _signalingServer;
  WebRtcTransferService? _webrtc;

  /// WebSocket-канал для связи с signaling-сервером получателя
  /// (только sender flow).
  WebSocketChannel? _wsChannel;
  StreamSubscription<dynamic>? _wsSubscription;

  // Для приёма файлов.
  IOSink? _currentFileSink;
  String? _currentFileName;
  int _currentFileSize = 0;
  int _currentFileReceived = 0;

  /// Completer для ожидания статуса prepare (accepted/rejected).
  Completer<bool>? _prepareCompleter;

  /// Completer для ожидания SDP answer.
  Completer<String>? _answerCompleter;

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
    // Очищаем предыдущую сессию перед новой передачей.
    await _cleanupCurrentTransfer();

    state = const TransferState.preparing();

    try {
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

      // Подключаемся к signaling-серверу получателя по WebSocket.
      final wsUrl = Uri.parse('ws://${target.ip}:${target.signalingPort}');
      _wsChannel = WebSocketChannel.connect(wsUrl);
      await _wsChannel!.ready;

      // Слушаем ответы от получателя.
      _prepareCompleter = Completer<bool>();
      _answerCompleter = Completer<String>();
      _wsSubscription = _wsChannel!.stream.listen(
        _handleSignalingResponse,
        onError: (Object error) {
          logError('Signaling WS error', error: error);
          if (!(_prepareCompleter?.isCompleted ?? true)) {
            _prepareCompleter?.completeError(error);
          }
          if (!(_answerCompleter?.isCompleted ?? true)) {
            _answerCompleter?.completeError(error);
          }
        },
        onDone: () {
          if (!(_prepareCompleter?.isCompleted ?? true)) {
            _prepareCompleter?.complete(false);
          }
        },
      );

      // Шлём prepare-запрос.
      _wsSend({'type': 'prepare', 'data': request.toJson()});

      state = const TransferState.waitingApproval();

      // Ожидаем подтверждения (с таймаутом 60с).
      final accepted = await _prepareCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );

      if (!accepted) {
        state = const TransferState.rejected();
        await _disconnectWs();
        return;
      }

      // Подтверждено — запускаем WebRTC handshake.
      state = const TransferState.connecting();

      _webrtc = WebRtcTransferService();
      _setupSenderCallbacks(files, text);

      // Создаём offer.
      final offerJson = await _webrtc!.createOffer();

      // Отправляем offer через WebSocket.
      _wsSend({'type': 'offer', 'data': offerJson});

      // Отправляем ICE candidates через WebSocket.
      _webrtc!.onLocalIceCandidate = (candidateJson) {
        _wsSend({'type': 'ice', 'data': candidateJson});
      };

      // Получаем answer (с таймаутом 30с).
      final answerJson = await _answerCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Answer timeout'),
      );
      await _webrtc!.handleAnswer(answerJson);

      // Ждём соединения — onConnected вызовет _startSending.
    } on SocketException catch (e, s) {
      logError('TransferNotifier.sendToDevice', error: e, stackTrace: s);
      state = TransferState.error(
        message:
            'Не удалось подключиться к устройству. '
            'Убедитесь, что оба устройства в одной сети. '
            '(${e.message})',
      );
      await _disconnectWs();
    } on TimeoutException catch (e) {
      logError('TransferNotifier.sendToDevice: timeout', error: e);
      state = const TransferState.error(
        message: 'Таймаут при подключении к устройству',
      );
      await _disconnectWs();
    } catch (e, s) {
      logError('TransferNotifier.sendToDevice', error: e, stackTrace: s);
      state = TransferState.error(message: e.toString());
      await _disconnectWs();
    }
  }

  /// Обрабатывает входящие сообщения от signaling-сервера
  /// получателя (sender side).
  void _handleSignalingResponse(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      switch (type) {
        case 'prepare_status':
          final data = message['data'] as Map<String, dynamic>?;
          final status = data?['status'] as String?;

          if (status == 'accepted') {
            _prepareCompleter?.complete(true);
          } else if (status == 'rejected') {
            _prepareCompleter?.complete(false);
          }
        // 'pending' — просто игнорируем, ждём дальше.

        case 'answer':
          final data = message['data'] as String?;
          if (data != null && !(_answerCompleter?.isCompleted ?? true)) {
            _answerCompleter?.complete(data);
          }

        case 'ice':
          final data = message['data'] as String?;
          if (data != null) {
            _webrtc?.addIceCandidate(data);
          }

        case 'offer_ack':
          // Подтверждение получения offer — ничего не делаем.
          break;

        case 'cancel_ack':
          // Подтверждение отмены.
          break;

        default:
          logInfo('TransferNotifier: unknown signaling response: $type');
      }
    } catch (e, s) {
      logError(
        'TransferNotifier: signaling response error',
        error: e,
        stackTrace: s,
      );
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
    // Очищаем предыдущую сессию перед новой.
    await _cleanupCurrentTransfer();

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
      // диалог покажет «Получено!» с кнопкой «Закрыть».
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

  /// Очищает текущую сессию передачи без сброса
  /// signaling-сервера.
  Future<void> _cleanupCurrentTransfer() async {
    await _webrtc?.dispose();
    _webrtc = null;

    await _disconnectWs();

    await _closeFileSink();
    _currentFileName = null;
    _currentFileSize = 0;
    _currentFileReceived = 0;
  }

  /// Безопасно закрывает IOSink для принимаемого файла.
  Future<void> _closeFileSink() async {
    try {
      await _currentFileSink?.flush();
      await _currentFileSink?.close();
    } catch (_) {
      // Файл уже закрыт или ошибка записи — игнорируем.
    }
    _currentFileSink = null;
  }

  /// Сбрасывает состояние.
  Future<void> reset() async {
    await _cleanupCurrentTransfer();

    await _signalingServer?.reset();

    ref.read(incomingRequestProvider.notifier).clear();
    state = const TransferState.idle();
  }

  Future<void> _dispose() async {
    await _cleanupCurrentTransfer();
    await _signalingServer?.stop();
  }

  // ══════════════════════════════════════════════
  //  WebSocket helpers (sender side)
  // ══════════════════════════════════════════════

  /// Отправляет JSON-сообщение по WebSocket.
  void _wsSend(Map<String, dynamic> message) {
    try {
      _wsChannel?.sink.add(jsonEncode(message));
    } catch (e) {
      logError('TransferNotifier: WS send error', error: e);
    }
  }

  /// Отключается от WebSocket получателя.
  Future<void> _disconnectWs() async {
    await _wsSubscription?.cancel();
    _wsSubscription = null;

    await _wsChannel?.sink.close();
    _wsChannel = null;

    _prepareCompleter = null;
    _answerCompleter = null;
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
