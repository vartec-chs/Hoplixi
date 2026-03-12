import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';
import 'package:hoplixi/features/local_send/providers/discovery_provider.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/session_history_provider.dart';
import 'package:hoplixi/features/local_send/services/signaling_server.dart';
import 'package:hoplixi/features/local_send/services/webrtc_transfer_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Провайдер состояния сессии обмена данными.
final transferProvider =
    NotifierProvider.autoDispose<SessionNotifier, SessionState>(
      SessionNotifier.new,
    );

/// Оркестрирует signaling-сервер, WebRTC-соединение
/// и процесс обмена файлами/текстом.
///
/// В отличие от одноразовой передачи, WebRTC-соединение
/// сохраняется между операциями — устройства могут свободно
/// обмениваться данными пока один из них не отключится.
class SessionNotifier extends Notifier<SessionState> {
  SignalingServer? _signalingServer;
  WebRtcTransferService? _webrtc;

  /// WebSocket-канал для связи с signaling-сервером
  /// удалённого устройства (только sender/initiator flow).
  WebSocketChannel? _wsChannel;
  StreamSubscription<dynamic>? _wsSubscription;

  // Для приёма файлов.
  IOSink? _currentFileSink;
  String? _currentFileName;
  int _currentFileSize = 0;
  int _currentFileReceived = 0;
  String? _currentFilePath;

  /// Peer, с которым установлена или устанавливается сессия.
  DeviceInfo? _connectedPeer;

  /// Completer для ожидания статуса prepare (accepted/rejected).
  Completer<bool>? _prepareCompleter;

  /// Completer для ожидания SDP answer.
  Completer<String>? _answerCompleter;

  @override
  SessionState build() {
    ref.onDispose(_dispose);

    // Держим discoveryProvider живым пока жив SessionNotifier.
    // ref.listen (не ref.watch) — не вызывает rebuild этого нотифайера
    // при изменениях списка устройств.
    ref.listen(discoveryProvider, (_, __) {});

    _startSignalingServer();
    return const SessionState.disconnected();
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

    logInfo('SessionNotifier: signaling on port $port');
  }

  // ══════════════════════════════════════════════
  //  Инициатор соединения (initiator flow)
  // ══════════════════════════════════════════════

  /// Подключается к устройству и устанавливает
  /// WebRTC-сессию.
  Future<void> connectToDevice(DeviceInfo target) async {
    await _cleanupCurrentSession();

    _connectedPeer = target;
    state = SessionState.waitingApproval(peer: target);

    try {
      final selfId = ref.read(localDeviceIdProvider);
      final selfIp = await _getSelfIp();
      final name = ref.read(localDeviceName);
      final platform = ref.read(localDevicePlatform);

      final senderDevice = DeviceInfo(
        id: selfId,
        name: name,
        ip: selfIp,
        signalingPort: _signalingServer?.port ?? 0,
        platform: platform,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      );

      // Подключаемся к signaling-серверу получателя.
      final wsUrl = Uri.parse('ws://${target.ip}:${target.signalingPort}');
      _wsChannel = WebSocketChannel.connect(wsUrl);
      await _wsChannel!.ready;

      // Слушаем ответы.
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

      // Шлём prepare-запрос (только device info).
      _wsSend({
        'type': 'prepare',
        'data': {'senderDevice': senderDevice.toJson()},
      });

      // Ожидаем подтверждения (60с).
      final accepted = await _prepareCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => false,
      );

      if (!accepted) {
        state = const SessionState.error(message: 'Запрос отклонён');
        await _disconnectWs();
        return;
      }

      // Подтверждено — запускаем WebRTC handshake.
      state = SessionState.connecting(peer: target);

      _webrtc = WebRtcTransferService();
      _setupCommonCallbacks();

      // Создаём offer.
      final offerJson = await _webrtc!.createOffer();

      // Отправляем offer через WebSocket.
      _wsSend({'type': 'offer', 'data': offerJson});

      // ICE candidates.
      _webrtc!.onLocalIceCandidate = (candidateJson) {
        _wsSend({'type': 'ice', 'data': candidateJson});
      };

      // Получаем answer (30с).
      final answerJson = await _answerCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Answer timeout'),
      );
      await _webrtc!.handleAnswer(answerJson);

      // Ждём onConnected → переход в connected.
    } on SocketException catch (e, s) {
      logError('connectToDevice', error: e, stackTrace: s);
      state = SessionState.error(
        message:
            'Не удалось подключиться к устройству. '
            'Убедитесь, что оба устройства в одной сети. '
            '(${e.message})',
      );
      await _disconnectWs();
    } on TimeoutException catch (e) {
      logError('connectToDevice: timeout', error: e);
      state = const SessionState.error(
        message: 'Таймаут при подключении к устройству',
      );
      await _disconnectWs();
    } catch (e, s) {
      logError('connectToDevice', error: e, stackTrace: s);
      state = SessionState.error(message: e.toString());
      await _disconnectWs();
    }
  }

  /// Обрабатывает входящие сообщения от signaling-сервера
  /// удалённого устройства (sender side).
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

        case 'offer_ack' || 'cancel_ack':
          break;

        default:
          logInfo('SessionNotifier: unknown signaling response: $type');
      }
    } catch (e, s) {
      logError(
        'SessionNotifier: signaling response error',
        error: e,
        stackTrace: s,
      );
    }
  }

  // ══════════════════════════════════════════════
  //  Получатель (receiver flow)
  // ══════════════════════════════════════════════

  void _onIncomingPrepare(DeviceInfo peerDevice) {
    // Показываем запрос в UI через provider.
    _connectedPeer = peerDevice;
    ref.read(incomingRequestProvider.notifier).setRequest(peerDevice);
    logInfo('Incoming connection from ${peerDevice.name}');
  }

  /// Принимает входящий запрос на соединение.
  Future<void> acceptIncomingSession() async {
    await _cleanupCurrentSession();

    final peer = _connectedPeer;
    if (peer == null) return;

    _signalingServer?.acceptTransfer();
    ref.read(incomingRequestProvider.notifier).clear();
    state = SessionState.connecting(peer: peer);

    // WebRTC для приёма.
    _webrtc = WebRtcTransferService();
    _setupCommonCallbacks();

    // Ждём offer.
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
  void rejectIncomingSession() {
    _signalingServer?.rejectTransfer();
    ref.read(incomingRequestProvider.notifier).clear();
    _connectedPeer = null;
    state = const SessionState.disconnected();
  }

  Future<void> _onOfferReceived(String offerJson) async {
    if (_webrtc == null) return;

    try {
      final answerJson = await _webrtc!.handleOffer(offerJson);
      _signalingServer?.setLocalAnswer(answerJson);
    } catch (e, s) {
      logError('_onOfferReceived error', error: e, stackTrace: s);
      state = SessionState.error(message: e.toString());
    }
  }

  // ══════════════════════════════════════════════
  //  Отправка данных (внутри сессии)
  // ══════════════════════════════════════════════

  /// Отправляет файлы по установленному соединению.
  Future<void> sendFiles(List<File> files) async {
    final peer = _connectedPeer;
    if (peer == null || _webrtc == null) return;

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = p.basename(file.path);

      state = SessionState.transferring(
        peer: peer,
        progress: 0,
        currentFile: fileName,
        currentIndex: i,
        totalFiles: files.length,
        isSending: true,
      );

      _webrtc!.onProgress = (sent, total) {
        state = SessionState.transferring(
          peer: peer,
          progress: sent / total,
          currentFile: fileName,
          currentIndex: i,
          totalFiles: files.length,
          isSending: true,
        );
      };

      await _webrtc!.sendFile(file);

      ref
          .read(sessionHistoryProvider.notifier)
          .add(
            HistoryItemType.fileSent,
            fileName,
            deviceName: peer.name,
            filePath: file.path,
          );
    }

    _webrtc!.sendTransferComplete();

    // Возвращаемся в connected — сессия не закрывается.
    state = SessionState.connected(peer: peer);
  }

  /// Отправляет текст по установленному соединению.
  Future<void> sendText(String text) async {
    if (_webrtc == null) return;
    await _webrtc!.sendText(text);

    ref
        .read(sessionHistoryProvider.notifier)
        .add(HistoryItemType.textSent, text, deviceName: _connectedPeer?.name);
  }

  // ══════════════════════════════════════════════
  //  Общие колбэки WebRTC
  // ══════════════════════════════════════════════

  void _setupCommonCallbacks() {
    _webrtc!.onConnected = () {
      logInfo('WebRTC connected — session active');
      final peer = _connectedPeer;
      if (peer != null) {
        state = SessionState.connected(peer: peer);
      }
    };

    _webrtc!.onFileStart = (fileName, fileSize) async {
      _currentFileName = fileName;
      _currentFileSize = fileSize;
      _currentFileReceived = 0;

      final downloadsDir = await _getDownloadsDir();
      final filePath = p.join(downloadsDir.path, fileName);
      _currentFilePath = filePath;
      final file = File(filePath);
      _currentFileSink = file.openWrite();

      final peer = _connectedPeer;
      if (peer != null) {
        state = SessionState.transferring(
          peer: peer,
          progress: 0,
          currentFile: fileName,
          currentIndex: 0,
          totalFiles: 1,
          isSending: false,
        );
      }
    };

    _webrtc!.onFileChunkReceived = (chunk) {
      _currentFileSink?.add(chunk);
      _currentFileReceived += chunk.length;

      if (_currentFileSize > 0) {
        final peer = _connectedPeer;
        if (peer != null) {
          state = SessionState.transferring(
            peer: peer,
            progress: _currentFileReceived / _currentFileSize,
            currentFile: _currentFileName ?? '',
            currentIndex: 0,
            totalFiles: 1,
            isSending: false,
          );
        }
      }
    };

    _webrtc!.onFileEnd = (fileName) async {
      await _closeFileSink();
      logInfo('File received: $fileName');

      final peer = _connectedPeer;

      ref
          .read(sessionHistoryProvider.notifier)
          .add(
            HistoryItemType.fileReceived,
            fileName,
            deviceName: peer?.name,
            filePath: _currentFilePath,
          );
      _currentFilePath = null;

      // Возвращаемся в connected.
      if (peer != null) {
        state = SessionState.connected(peer: peer);
      }
    };

    _webrtc!.onTextReceived = (text) {
      logInfo('Text received: $text');

      ref
          .read(sessionHistoryProvider.notifier)
          .add(
            HistoryItemType.textReceived,
            text,
            deviceName: _connectedPeer?.name,
          );
    };

    _webrtc!.onTransferComplete = () {
      // Партнёр завершил передачу — возвращаемся
      // в connected.
      final peer = _connectedPeer;
      if (peer != null) {
        state = SessionState.connected(peer: peer);
      }
    };

    _webrtc!.onCancelled = () {
      state = const SessionState.error(message: 'Передача отменена');
    };

    _webrtc!.onDisconnected = () {
      logInfo('Peer disconnected gracefully');
      disconnect();
    };

    _webrtc!.onError = (error) {
      state = SessionState.error(message: error);
    };
  }

  // ══════════════════════════════════════════════
  //  Управление сессией
  // ══════════════════════════════════════════════

  /// Останавливает WebRTC, signaling-сервер и регистрирует поля
  /// без изменения [state]. Предназначен для вызова из dispose()
  /// виджета (fire-and-forget) — не бросает исключений.
  Future<void> stopServices() async {
    try {
      await _cleanupCurrentSession();
      await _signalingServer?.stop();
    } catch (_) {}
  }

  /// Отключается от peer и сбрасывает сессию.
  Future<void> disconnect() async {
    // Уведомляем другую сторону до закрытия каналов.
    _webrtc?.sendDisconnect();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _cleanupCurrentSession();
    await _signalingServer?.reset();

    ref.read(incomingRequestProvider.notifier).clear();
    ref.read(sessionHistoryProvider.notifier).clear();
    _connectedPeer = null;
    state = const SessionState.disconnected();
  }

  /// Сбрасывает состояние (alias для disconnect).
  Future<void> reset() async => disconnect();

  /// Очищает текущую WebRTC/WS сессию.
  Future<void> _cleanupCurrentSession() async {
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
      // Файл уже закрыт или ошибка записи.
    }
    _currentFileSink = null;
  }

  Future<void> _dispose() async {
    await _cleanupCurrentSession();
    await _signalingServer?.stop();
  }

  // ══════════════════════════════════════════════
  //  WebSocket helpers (initiator side)
  // ══════════════════════════════════════════════

  void _wsSend(Map<String, dynamic> message) {
    try {
      _wsChannel?.sink.add(jsonEncode(message));
    } catch (e) {
      logError('SessionNotifier: WS send error', error: e);
    }
  }

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

  Future<Directory> _getDownloadsDir() async {
    final dir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return dir;
  }
}
