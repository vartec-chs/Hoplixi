import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/index.dart' hide DeviceInfo;
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/local_send/models/cloud_sync_tokens_transfer_payload.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';
import 'package:hoplixi/features/local_send/models/encrypted_transfer_envelope.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:hoplixi/features/local_send/models/session_state.dart';
import 'package:hoplixi/features/local_send/providers/discovery_provider.dart';
import 'package:hoplixi/features/local_send/providers/incoming_request_provider.dart';
import 'package:hoplixi/features/local_send/providers/local_send_route_state_provider.dart';
import 'package:hoplixi/features/local_send/providers/session_history_provider.dart';
import 'package:hoplixi/features/local_send/services/local_send_secure_payload_crypto_service.dart';
import 'package:hoplixi/features/local_send/services/signaling_server.dart';
import 'package:hoplixi/features/local_send/services/webrtc_transfer_service.dart';
import 'package:hoplixi/main_db/models/store_folder_info.dart';
import 'package:hoplixi/main_db/providers/archive_provider.dart';
import 'package:hoplixi/main_db/services/archive_service/archive_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Провайдер состояния сессии обмена данными.
final transferProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// Оркестрирует signaling-сервер, WebRTC-соединение
/// и процесс обмена файлами/текстом.
///
/// В отличие от одноразовой передачи, WebRTC-соединение
/// сохраняется между операциями — устройства могут свободно
/// обмениваться данными пока один из них не отключится.
class SessionNotifier extends Notifier<SessionState> {
  static const Duration _incomingFileTimeout = Duration(seconds: 20);
  static const String _authTokensPayloadLabel =
      'Зашифрованный пакет OAuth-токенов';

  SignalingServer? _signalingServer;
  WebRtcTransferService? _webrtc;
  final LocalSendSecurePayloadCryptoService _securePayloadCrypto =
      const LocalSendSecurePayloadCryptoService();

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
  final List<List<int>> _pendingFileChunks = [];
  bool _currentFileEndReceived = false;
  bool _isFinalizingCurrentFile = false;
  Timer? _incomingFileTimeoutTimer;

  /// Peer, с которым установлена или устанавливается сессия.
  DeviceInfo? _connectedPeer;

  /// Completer для ожидания статуса prepare (accepted/rejected).
  Completer<bool>? _prepareCompleter;

  /// Completer для ожидания SDP answer.
  Completer<String>? _answerCompleter;

  @override
  SessionState build() {
    ref.onDispose(_dispose);

    _startSignalingServer();
    return const SessionState.disconnected();
  }

  void _setSessionState(SessionState nextState) {
    state = nextState;
    ref.read(localSendRouteStateProvider.notifier).syncWithSession(nextState);
  }

  void _resetRouteState() {
    ref.read(localSendRouteStateProvider.notifier).showDiscovery();
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
    _setSessionState(SessionState.waitingApproval(peer: target));

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
        _setSessionState(const SessionState.error(message: 'Запрос отклонён'));
        await _disconnectWs();
        return;
      }

      // Подтверждено — запускаем WebRTC handshake.
      _setSessionState(SessionState.connecting(peer: target));

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
      _setSessionState(
        SessionState.error(
          message:
              'Не удалось подключиться к устройству. '
              'Убедитесь, что оба устройства в одной сети. '
              '(${e.message})',
        ),
      );
      await _disconnectWs();
    } on TimeoutException catch (e) {
      logError('connectToDevice: timeout', error: e);
      _setSessionState(
        const SessionState.error(
          message: 'Таймаут при подключении к устройству',
        ),
      );
      await _disconnectWs();
    } catch (e, s) {
      logError('connectToDevice', error: e, stackTrace: s);
      _setSessionState(SessionState.error(message: e.toString()));
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
    _setSessionState(SessionState.connecting(peer: peer));

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
    _setSessionState(const SessionState.disconnected());
  }

  Future<void> _onOfferReceived(String offerJson) async {
    if (_webrtc == null) return;

    try {
      final answerJson = await _webrtc!.handleOffer(offerJson);
      _signalingServer?.setLocalAnswer(answerJson);
    } catch (e, s) {
      logError('_onOfferReceived error', error: e, stackTrace: s);
      _setSessionState(SessionState.error(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════
  //  Отправка данных (внутри сессии)
  // ══════════════════════════════════════════════

  /// Отправляет файлы по установленному соединению.
  Future<void> sendFiles(List<File> files) async {
    final peer = _connectedPeer;
    if (peer == null || _webrtc == null) return;

    try {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = p.basename(file.path);

        _setSessionState(
          SessionState.transferring(
            peer: peer,
            progress: 0,
            currentFile: fileName,
            currentIndex: i,
            totalFiles: files.length,
            isSending: true,
          ),
        );

        _webrtc!.onProgress = (sent, total) {
          _setSessionState(
            SessionState.transferring(
              peer: peer,
              progress: sent / total,
              currentFile: fileName,
              currentIndex: i,
              totalFiles: files.length,
              isSending: true,
            ),
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

      await _webrtc!.sendTransferComplete();

      // Возвращаемся в connected — сессия не закрывается.
      _setSessionState(SessionState.connected(peer: peer));
    } catch (e, s) {
      logError('sendFiles', error: e, stackTrace: s);
      _setSessionState(
        const SessionState.error(
          message: 'Не удалось завершить передачу файлов',
        ),
      );
    }
  }

  /// Архивирует хранилище и отправляет его как ZIP-файл.
  Future<void> sendStoreArchive(
    StoreFolderInfo store, {
    String? password,
  }) async {
    final peer = _connectedPeer;
    if (peer == null || _webrtc == null) return;

    final archiveService = ref.read(archiveServiceProvider);
    final outputPath = await _buildStoreArchivePath(store.storeName);

    _setSessionState(
      SessionState.transferring(
        peer: peer,
        progress: 0,
        currentFile: 'Подготовка архива ${store.storeName}',
        currentIndex: 0,
        totalFiles: 1,
        isSending: true,
      ),
    );

    try {
      final result = await archiveService.archiveStore(
        store.folderPath,
        outputPath,
        password: password,
        onProgress: (current, total, fileName) {
          _setSessionState(
            SessionState.transferring(
              peer: peer,
              progress: total <= 0 ? 0 : current / total,
              currentFile: 'Архивация: $fileName',
              currentIndex: 0,
              totalFiles: 1,
              isSending: true,
            ),
          );
        },
      );

      if (result.isError()) {
        final error = result.fold((_) => null, (error) => error);
        Toaster.error(
          title: 'Ошибка архивации',
          description:
              error?.message ?? 'Не удалось подготовить архив хранилища',
        );
        _setSessionState(SessionState.connected(peer: peer));
        return;
      }

      await sendFiles([File(result.getOrThrow())]);
    } catch (e, s) {
      logError('sendStoreArchive', error: e, stackTrace: s);
      Toaster.error(
        title: 'Ошибка отправки',
        description: 'Не удалось отправить хранилище: $e',
      );
      _setSessionState(SessionState.connected(peer: peer));
    }
  }

  /// Отправляет текст по установленному соединению.
  Future<void> sendText(String text) async {
    if (_webrtc == null) return;
    await _webrtc!.sendText(text);

    ref
        .read(sessionHistoryProvider.notifier)
        .add(HistoryItemType.textSent, text, deviceName: _connectedPeer?.name);
  }

  /// Отправляет защищённый пакет OAuth-токенов cloud sync.
  Future<void> sendCloudSyncTokens(
    List<AuthTokenEntry> tokens, {
    required String password,
    CloudSyncTokenExportMode exportMode =
        CloudSyncTokenExportMode.withoutRefresh,
  }) async {
    final peer = _connectedPeer;
    if (peer == null || _webrtc == null || tokens.isEmpty) {
      return;
    }

    try {
      final payload = CloudSyncTokensTransferPayload.forExport(
        tokens: tokens,
        exportMode: exportMode,
      );
      final envelope = await _securePayloadCrypto.encryptCloudSyncTokens(
        payload: payload,
        password: password,
      );

      await _webrtc!.sendSecurePayload(envelope.toJson());

      ref
          .read(sessionHistoryProvider.notifier)
          .add(
            HistoryItemType.authTokensSent,
            tokens.length == 1
                ? 'OAuth токен (${tokens.first.displayLabel})'
                : 'OAuth токены (${tokens.length})',
            deviceName: peer.name,
            encryptedEnvelope: envelope,
          );

      Toaster.success(
        title: 'OAuth-токены отправлены',
        description: exportMode == CloudSyncTokenExportMode.withoutRefresh
            ? 'Отправлен защищённый пакет без refresh token.'
            : 'Отправлен полный защищённый пакет OAuth-токенов.',
      );
    } on LocalSendSecurePayloadException catch (error) {
      Toaster.error(title: 'Ошибка шифрования', description: error.message);
    } catch (error, stackTrace) {
      logError('sendCloudSyncTokens', error: error, stackTrace: stackTrace);
      Toaster.error(
        title: 'Ошибка отправки',
        description: 'Не удалось отправить OAuth-токены: $error',
      );
    }
  }

  // ══════════════════════════════════════════════
  //  Общие колбэки WebRTC
  // ══════════════════════════════════════════════

  void _setupCommonCallbacks() {
    _webrtc!.onConnected = () {
      logInfo('WebRTC connected — session active');
      final peer = _connectedPeer;
      if (peer != null) {
        _setSessionState(SessionState.connected(peer: peer));
      }
    };

    _webrtc!.onFileStart = (fileName, fileSize) async {
      await _closeFileSink();
      _pendingFileChunks.clear();
      _currentFileName = fileName;
      _currentFileSize = fileSize;
      _currentFileReceived = 0;
      _currentFileEndReceived = false;
      _isFinalizingCurrentFile = false;
      _currentFilePath = null;

      final downloadsDir = await _getDownloadsDir();
      if (_currentFileName != fileName) {
        return;
      }

      final filePath = p.join(downloadsDir.path, fileName);
      _currentFilePath = filePath;
      final file = File(filePath);
      _currentFileSink = file.openWrite();
      _restartIncomingFileTimeout();
      _flushPendingFileChunks();
      unawaited(_maybeFinalizeIncomingFile());

      final peer = _connectedPeer;
      if (peer != null) {
        _setSessionState(
          SessionState.transferring(
            peer: peer,
            progress: 0,
            currentFile: fileName,
            currentIndex: 0,
            totalFiles: 1,
            isSending: false,
          ),
        );
      }
    };

    _webrtc!.onFileChunkReceived = (chunk) {
      _handleIncomingFileChunk(chunk);
    };

    _webrtc!.onFileEnd = (fileName) async {
      if (_currentFileName != null && _currentFileName != fileName) {
        logInfo(
          'SessionNotifier: file_end for unexpected file '
          '$fileName, current file: $_currentFileName',
        );
      }
      _currentFileEndReceived = true;
      _restartIncomingFileTimeout();
      await _maybeFinalizeIncomingFile();
    };

    _webrtc!.onTextReceived = (text) {
      logInfo('Text received (${text.length} chars)');

      ref
          .read(sessionHistoryProvider.notifier)
          .add(
            HistoryItemType.textReceived,
            text,
            deviceName: _connectedPeer?.name,
          );
    };

    _webrtc!.onSecurePayloadReceived = (payloadJson) {
      _handleIncomingSecurePayload(payloadJson);
    };

    _webrtc!.onTransferComplete = () {
      if (_currentFileName != null &&
          _currentFileReceived < _currentFileSize &&
          !_isFinalizingCurrentFile) {
        unawaited(
          _abortIncomingFile(
            message: 'Передача прервана: файл получен не полностью',
            notifyPeer: false,
          ),
        );
        return;
      }

      // Партнёр завершил передачу — возвращаемся
      // в connected.
      final peer = _connectedPeer;
      if (peer != null) {
        _setSessionState(SessionState.connected(peer: peer));
      }
    };

    _webrtc!.onCancelled = () {
      unawaited(_discardPartialIncomingFile());
      _setSessionState(const SessionState.error(message: 'Передача отменена'));
    };

    _webrtc!.onDisconnected = () {
      logInfo('Peer disconnected gracefully');
      disconnect();
    };

    _webrtc!.onError = (error) {
      _setSessionState(SessionState.error(message: error));
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
    ref.invalidate(discoveryProvider);
    _resetRouteState();
  }

  /// Отключается от peer и сбрасывает сессию.
  Future<void> disconnect() async {
    // Уведомляем другую сторону до закрытия каналов.
    unawaited(_webrtc?.sendDisconnect());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _cleanupCurrentSession();
    await _signalingServer?.reset();

    ref.read(incomingRequestProvider.notifier).clear();
    ref.read(sessionHistoryProvider.notifier).clear();
    _connectedPeer = null;
    _setSessionState(const SessionState.disconnected());
  }

  /// Сбрасывает состояние (alias для disconnect).
  Future<void> reset() async => disconnect();

  /// Очищает текущую WebRTC/WS сессию.
  Future<void> _cleanupCurrentSession() async {
    _cancelIncomingFileTimeout();
    await _webrtc?.dispose();
    _webrtc = null;

    await _disconnectWs();

    await _closeFileSink();
    _resetIncomingFileState();
  }

  /// Безопасно закрывает IOSink для принимаемого файла.
  Future<void> _closeFileSink() async {
    final sink = _currentFileSink;
    _currentFileSink = null;

    try {
      await sink?.flush();
      await sink?.close();
    } catch (_) {
      // Файл уже закрыт или ошибка записи.
    }
  }

  void _handleIncomingFileChunk(List<int> chunk) {
    if (_currentFileName == null) {
      logInfo('SessionNotifier: chunk received without active file');
      return;
    }

    if (_isFinalizingCurrentFile) {
      logInfo(
        'SessionNotifier: chunk ignored while finalizing '
        '${_currentFileName ?? 'unknown file'}',
      );
      return;
    }

    if (_currentFileSink == null) {
      _pendingFileChunks.add(List<int>.from(chunk));
      return;
    }

    try {
      final writableChunk = _trimChunkToExpectedSize(chunk);
      if (writableChunk.isEmpty) {
        return;
      }

      _currentFileSink!.add(writableChunk);
      _currentFileReceived += writableChunk.length;
      _restartIncomingFileTimeout();
      _updateIncomingTransferProgress();

      if (_currentFileEndReceived &&
          _currentFileReceived >= _currentFileSize &&
          !_isFinalizingCurrentFile) {
        unawaited(_maybeFinalizeIncomingFile());
      }
    } catch (e, s) {
      logError(
        'SessionNotifier: failed to write file chunk',
        error: e,
        stackTrace: s,
      );
      _setSessionState(
        const SessionState.error(
          message: 'Не удалось записать принимаемый файл',
        ),
      );
    }
  }

  List<int> _trimChunkToExpectedSize(List<int> chunk) {
    if (_currentFileSize <= 0) {
      return chunk;
    }

    final remaining = _currentFileSize - _currentFileReceived;
    if (remaining <= 0) {
      logInfo(
        'SessionNotifier: extra chunk ignored for '
        '${_currentFileName ?? 'unknown file'}',
      );
      return const [];
    }

    if (chunk.length <= remaining) {
      return chunk;
    }

    logInfo(
      'SessionNotifier: trimming oversized chunk for '
      '${_currentFileName ?? 'unknown file'}',
    );
    return chunk.sublist(0, remaining);
  }

  void _flushPendingFileChunks() {
    if (_currentFileSink == null || _pendingFileChunks.isEmpty) {
      return;
    }

    final pendingChunks = List<List<int>>.from(_pendingFileChunks);
    _pendingFileChunks.clear();
    for (final pendingChunk in pendingChunks) {
      _handleIncomingFileChunk(pendingChunk);
    }
  }

  void _updateIncomingTransferProgress() {
    if (_currentFileSize <= 0) {
      return;
    }

    final peer = _connectedPeer;
    if (peer == null) {
      return;
    }

    _setSessionState(
      SessionState.transferring(
        peer: peer,
        progress: _currentFileReceived / _currentFileSize,
        currentFile: _currentFileName ?? '',
        currentIndex: 0,
        totalFiles: 1,
        isSending: false,
      ),
    );
  }

  Future<void> _maybeFinalizeIncomingFile() async {
    if (_isFinalizingCurrentFile ||
        !_currentFileEndReceived ||
        _currentFileName == null ||
        _currentFileSink == null ||
        _currentFileReceived < _currentFileSize) {
      return;
    }

    _isFinalizingCurrentFile = true;
    _cancelIncomingFileTimeout();
    final completedFileName = _currentFileName!;
    final completedFilePath = _currentFilePath;

    await _closeFileSink();
    logInfo('File received: $completedFileName');

    final peer = _connectedPeer;

    ref
        .read(sessionHistoryProvider.notifier)
        .add(
          HistoryItemType.fileReceived,
          completedFileName,
          deviceName: peer?.name,
          filePath: completedFilePath,
        );
    _resetIncomingFileState();

    if (peer != null) {
      _setSessionState(SessionState.connected(peer: peer));
    }

    unawaited(_webrtc?.sendFileReceived(completedFileName));
  }

  void _resetIncomingFileState() {
    _cancelIncomingFileTimeout();
    _currentFileName = null;
    _currentFileSize = 0;
    _currentFileReceived = 0;
    _currentFilePath = null;
    _pendingFileChunks.clear();
    _currentFileEndReceived = false;
    _isFinalizingCurrentFile = false;
  }

  void _restartIncomingFileTimeout() {
    if (_currentFileName == null || _isFinalizingCurrentFile) {
      return;
    }

    _incomingFileTimeoutTimer?.cancel();
    _incomingFileTimeoutTimer = Timer(_incomingFileTimeout, () {
      unawaited(
        _abortIncomingFile(
          message: 'Приём файла прерван: таймаут ожидания данных',
        ),
      );
    });
  }

  void _cancelIncomingFileTimeout() {
    _incomingFileTimeoutTimer?.cancel();
    _incomingFileTimeoutTimer = null;
  }

  Future<void> _abortIncomingFile({
    required String message,
    bool notifyPeer = true,
  }) async {
    if (_currentFileName == null && _currentFileSink == null) {
      _setSessionState(SessionState.error(message: message));
      return;
    }

    final failedFileName = _currentFileName;
    logInfo('SessionNotifier: aborting incoming file ${failedFileName ?? ''}');

    if (notifyPeer) {
      unawaited(_webrtc?.cancelTransfer());
    }

    await _discardPartialIncomingFile();
    _setSessionState(SessionState.error(message: message));
  }

  Future<void> _discardPartialIncomingFile() async {
    final partialPath = _currentFilePath;
    await _closeFileSink();

    if (partialPath != null) {
      final partialFile = File(partialPath);
      if (await partialFile.exists()) {
        try {
          await partialFile.delete();
        } catch (e, s) {
          logError(
            'SessionNotifier: failed to delete partial file',
            error: e,
            stackTrace: s,
          );
        }
      }
    }

    _resetIncomingFileState();
  }

  Future<void> _dispose() async {
    await _cleanupCurrentSession();
    await _signalingServer?.stop();
    ref.invalidate(discoveryProvider);
    _resetRouteState();
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

  Future<String> _buildStoreArchivePath(String storeName) async {
    final tempPath = await AppPaths.tempPath;
    final archiveDir = Directory(p.join(tempPath, 'local_send_store_archives'));
    if (!await archiveDir.exists()) {
      await archiveDir.create(recursive: true);
    }

    final safeStoreName = storeName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim();
    return p.join(
      archiveDir.path,
      '${safeStoreName.isEmpty ? 'store' : safeStoreName}${ArchiveService.storeArchiveFileSuffix}',
    );
  }

  void _handleIncomingSecurePayload(Map<String, dynamic> payloadJson) {
    try {
      final envelope = EncryptedTransferEnvelope.fromJson(
        _normalizeJsonMap(payloadJson),
      );

      if (envelope.kind != SecurePayloadKind.cloudSyncAuthTokens) {
        logInfo('SessionNotifier: unsupported secure payload kind');
        return;
      }

      ref
          .read(sessionHistoryProvider.notifier)
          .add(
            HistoryItemType.authTokensReceived,
            _authTokensPayloadLabel,
            deviceName: _connectedPeer?.name,
            encryptedEnvelope: envelope,
          );

      Toaster.info(
        title: 'Получен защищённый пакет OAuth-токенов',
        description: 'Нажмите на запись в истории, чтобы импортировать его.',
      );
    } catch (error, stackTrace) {
      logError(
        'SessionNotifier: failed to parse secure payload',
        error: error,
        stackTrace: stackTrace,
      );
      Toaster.error(
        title: 'Ошибка приёма',
        description: 'Не удалось обработать защищённый пакет.',
      );
    }
  }

  Map<String, dynamic> _normalizeJsonMap(Map raw) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), _normalizeJsonValue(value)),
    );
  }

  dynamic _normalizeJsonValue(Object? value) {
    if (value is Map) {
      return _normalizeJsonMap(value);
    }

    if (value is List) {
      return value.map(_normalizeJsonValue).toList(growable: false);
    }

    return value;
  }
}
