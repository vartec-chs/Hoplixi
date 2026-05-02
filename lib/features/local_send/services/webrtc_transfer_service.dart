import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/logger.dart';

/// Размер чанка для передачи файлов (16 KB).
const int kChunkSize = 16 * 1024;

/// Размер чанка для передачи текстовых сообщений (8 KB).
const int kTextMessageChunkSize = 8 * 1024;

/// Типы control-сообщений через DataChannel.
class DataChannelMessage {
  static const String fileStart = 'file_start';
  static const String fileEnd = 'file_end';
  static const String fileReceived = 'file_received';
  static const String textMessage = 'text_message';
  static const String textMessageStart = 'text_message_start';
  static const String textMessageChunk = 'text_message_chunk';
  static const String textMessageEnd = 'text_message_end';
  static const String securePayload = 'secure_payload';
  static const String transferComplete = 'transfer_complete';
  static const String cancel = 'cancel';
  static const String disconnect = 'disconnect';
}

/// Сервис для P2P-передачи файлов и текста
/// через WebRTC DataChannel.
class WebRtcTransferService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _controlChannel;
  RTCDataChannel? _dataChannel;
  bool _isDisposed = false;

  /// Флаг: соединение уже было установлено.
  /// Предотвращает повторный вызов [onConnected]
  /// при переходах ICE Connected → Completed → Connected.
  bool _hasConnected = false;

  /// Флаг: передача завершена (отправлен или получен
  /// `transfer_complete`). После этого ICE-ошибки
  /// игнорируются, т.к. Disconnected/Failed — нормальное
  /// поведение при закрытии соединения.
  bool _isTransferDone = false;
  Completer<void>? _fileReceivedCompleter;
  String? _pendingFileAckName;
  String? _incomingTextTransferId;
  BytesBuilder? _incomingTextBytes;
  int _incomingTextLength = 0;

  // ── Колбэки ──

  /// Вызывается при получении текстового сообщения.
  void Function(String text)? onTextReceived;

  /// Вызывается при получении зашифрованного payload.
  void Function(Map<String, dynamic> payload)? onSecurePayloadReceived;

  /// Начало приёма файла.
  void Function(String fileName, int fileSize)? onFileStart;

  /// Получен чанк файла.
  void Function(Uint8List chunk)? onFileChunkReceived;

  /// Файл полностью принят.
  void Function(String fileName)? onFileEnd;

  /// Обновление прогресса: (bytesTransferred, totalBytes).
  void Function(int bytesTransferred, int totalBytes)? onProgress;

  /// Передача полностью завершена.
  void Function()? onTransferComplete;

  /// Передача отменена удалённой стороной.
  void Function()? onCancelled;

  /// Удалённая сторона намеренно отключилась.
  void Function()? onDisconnected;

  /// Локальный ICE candidate готов для отправки.
  void Function(String candidateJson)? onLocalIceCandidate;

  /// Соединение установлено.
  void Function()? onConnected;

  /// Ошибка соединения.
  void Function(String error)? onError;

  /// Конфигурация WebRTC для LAN.
  static final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
  };

  /// Создаёт PeerConnection и SDP offer (отправитель).
  Future<String> createOffer() async {
    _isDisposed = false;
    await _createPeerConnection();

    // Создаём DataChannel для control-сообщений.
    _controlChannel = await _peerConnection!.createDataChannel(
      'control',
      RTCDataChannelInit()..ordered = true,
    );
    _setupControlChannel(_controlChannel!);

    // Создаём DataChannel для бинарных данных.
    _dataChannel = await _peerConnection!.createDataChannel(
      'fileTransfer',
      RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 30,
    );
    _setupDataChannel(_dataChannel!);

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    return jsonEncode({'sdp': offer.sdp, 'type': offer.type});
  }

  /// Обрабатывает полученный SDP offer и создаёт answer
  /// (получатель).
  Future<String> handleOffer(String offerJson) async {
    _isDisposed = false;
    await _createPeerConnection();

    // Слушаем входящие DataChannel.
    _peerConnection!.onDataChannel = (channel) {
      if (channel.label == 'control') {
        _controlChannel = channel;
        _setupControlChannel(channel);
      } else if (channel.label == 'fileTransfer') {
        _dataChannel = channel;
        _setupDataChannel(channel);
      }
    };

    final offerMap = jsonDecode(offerJson) as Map<String, dynamic>;
    final offer = RTCSessionDescription(
      offerMap['sdp'] as String?,
      offerMap['type'] as String?,
    );

    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    return jsonEncode({'sdp': answer.sdp, 'type': answer.type});
  }

  /// Обрабатывает полученный SDP answer (отправитель).
  ///
  /// Устанавливает remote description с типом `answer`.
  /// Вызывается только на стороне отправителя после получения
  /// ответа от получателя.
  Future<void> handleAnswer(String answerJson) async {
    final answerMap = jsonDecode(answerJson) as Map<String, dynamic>;
    final answer = RTCSessionDescription(
      answerMap['sdp'] as String?,
      answerMap['type'] as String?,
    );

    await _peerConnection!.setRemoteDescription(answer);
  }

  /// Добавляет удалённый ICE candidate.
  Future<void> addIceCandidate(String candidateJson) async {
    final map = jsonDecode(candidateJson) as Map<String, dynamic>;
    final candidate = RTCIceCandidate(
      map['candidate'] as String?,
      map['sdpMid'] as String?,
      map['sdpMLineIndex'] as int?,
    );
    await _peerConnection?.addCandidate(candidate);
  }

  /// Отправляет текстовое сообщение через control-канал.
  Future<void> sendText(String text) async {
    _ensureControlChannel();

    final bytes = Uint8List.fromList(utf8.encode(text));

    if (bytes.length <= kTextMessageChunkSize) {
      final message = jsonEncode({
        'type': DataChannelMessage.textMessage,
        'text': text,
      });
      await _sendControlMessage(message);
      return;
    }

    await _sendChunkedText(bytes);
  }

  /// Отправляет секретный payload через control-канал.
  Future<void> sendSecurePayload(Map<String, dynamic> payload) async {
    _ensureControlChannel();

    final message = jsonEncode({
      'type': DataChannelMessage.securePayload,
      'payload': payload,
    });
    await _sendControlMessage(message);
  }

  /// Отправляет один файл через DataChannel.
  ///
  /// Прогресс отправки обновляется через [onProgress].
  Future<void> sendFile(File file) async {
    _ensureControlChannel();
    _ensureDataChannel();

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();
    _pendingFileAckName = fileName;
    _fileReceivedCompleter = Completer<void>();

    try {
      // Уведомляем о начале файла.
      final startMsg = jsonEncode({
        'type': DataChannelMessage.fileStart,
        'name': fileName,
        'size': fileSize,
      });
      await _sendControlMessage(startMsg);

      // Ждём чтобы control-сообщение дошло раньше данных.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Стримим файл чанками.
      final stream = file.openRead();
      var bytesSent = 0;

      await for (final chunk in stream) {
        final bytes = Uint8List.fromList(chunk);

        // Разбиваем большие чанки.
        for (var offset = 0; offset < bytes.length; offset += kChunkSize) {
          final end = (offset + kChunkSize > bytes.length)
              ? bytes.length
              : offset + kChunkSize;
          final subChunk = bytes.sublist(offset, end);

          await _sendDataChunk(subChunk);
          bytesSent += subChunk.length;
          final visualProgressBytes = bytesSent >= fileSize
              ? math.max(fileSize - 1, 0)
              : bytesSent;
          onProgress?.call(visualProgressBytes, fileSize);

          // Даём DataChannel время на отправку, чтобы
          // не переполнить буфер.
          if ((_dataChannel!.bufferedAmount ?? 0) > kChunkSize * 16) {
            await _waitForBufferDrain();
          }
        }
      }

      // Уведомляем о конце файла.
      final endMsg = jsonEncode({
        'type': DataChannelMessage.fileEnd,
        'name': fileName,
      });
      await _sendControlMessage(endMsg);

      await _fileReceivedCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
            throw TimeoutException('File receive ack timeout: $fileName'),
      );

      onProgress?.call(fileSize, fileSize);

      logInfo('WebRtcTransfer: file sent: $fileName ($fileSize bytes)');
    } finally {
      _pendingFileAckName = null;
      _fileReceivedCompleter = null;
    }
  }

  /// Подтверждает, что файл полностью записан на стороне получателя.
  Future<void> sendFileReceived(String fileName) async {
    if (_controlChannel == null) return;

    try {
      final msg = jsonEncode({
        'type': DataChannelMessage.fileReceived,
        'name': fileName,
      });
      await _sendControlMessage(msg);
    } catch (e) {
      logError('WebRtcTransfer: sendFileReceived error', error: e);
    }
  }

  /// Уведомляет удалённую сторону о завершении передачи.
  Future<void> sendTransferComplete() async {
    if (_controlChannel == null) return;

    _isTransferDone = true;
    try {
      final msg = jsonEncode({'type': DataChannelMessage.transferComplete});
      await _sendControlMessage(msg);
    } catch (e) {
      logError('WebRtcTransfer: sendTransferComplete error', error: e);
    }
  }

  /// Отменяет передачу.
  Future<void> cancelTransfer() async {
    if (_controlChannel == null) return;

    try {
      final msg = jsonEncode({'type': DataChannelMessage.cancel});
      await _sendControlMessage(msg);
    } catch (e) {
      logError('WebRtcTransfer: cancelTransfer error', error: e);
    }
  }

  /// Уведомляет удалённую сторону о намеренном отключении.
  Future<void> sendDisconnect() async {
    if (_controlChannel == null) return;

    try {
      final msg = jsonEncode({'type': DataChannelMessage.disconnect});
      await _sendControlMessage(msg);
    } catch (e) {
      logError('WebRtcTransfer: sendDisconnect error', error: e);
    }
  }

  /// Освобождает ресурсы.
  ///
  /// Сначала обнуляет все колбэки, чтобы предотвратить
  /// нежелательные срабатывания во время очистки.
  /// Затем безопасно закрывает каналы и PeerConnection.
  Future<void> dispose() async {
    // Отключаем все колбэки первым делом, чтобы
    // ICE-события и DataChannel-сообщения, пришедшие
    // во время очистки, не вызвали ошибок.
    _clearCallbacks();
    _isTransferDone = true;
    _isDisposed = true;

    final peer = _peerConnection;

    // flutter_webrtc close() у RTCDataChannel может прислать late-event
    // после закрытия внутренних StreamController. Это и даёт
    // "Bad state: Cannot add event after closing". Оставляем закрытие
    // peer connection на стороне PeerConnection.
    _controlChannel = null;
    _dataChannel = null;
    _peerConnection = null;

    try {
      await peer?.close();
    } catch (_) {}

    try {
      await peer?.dispose();
    } catch (_) {}

    logInfo('WebRtcTransfer: disposed');
  }

  void _clearCallbacks() {
    onTextReceived = null;
    onSecurePayloadReceived = null;
    onFileStart = null;
    onFileChunkReceived = null;
    onFileEnd = null;
    onProgress = null;
    onTransferComplete = null;
    onCancelled = null;
    onDisconnected = null;
    onLocalIceCandidate = null;
    onConnected = null;
    onError = null;
    _pendingFileAckName = null;
    _fileReceivedCompleter = null;
    _resetIncomingTextTransfer();
  }

  // ── Private ──

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_rtcConfig);

    _peerConnection!.onIceCandidate = (candidate) {
      final json = jsonEncode({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
      onLocalIceCandidate?.call(json);
    };

    _peerConnection!.onIceConnectionState = (iceState) {
      logTrace('WebRTC ICE state: $iceState');

      if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected &&
          !_hasConnected) {
        _hasConnected = true;
        onConnected?.call();
      } else if (!_isTransferDone &&
          (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
              iceState ==
                  RTCIceConnectionState.RTCIceConnectionStateDisconnected)) {
        onError?.call('WebRTC connection failed: $iceState');
      }
    };
  }

  void _setupControlChannel(RTCDataChannel channel) {
    channel.onMessage = (message) {
      try {
        final json = jsonDecode(message.text) as Map<String, dynamic>;
        final type = json['type'] as String;

        switch (type) {
          case DataChannelMessage.textMessage:
            onTextReceived?.call(json['text'] as String);
          case DataChannelMessage.textMessageStart:
            _handleIncomingTextStart(json);
          case DataChannelMessage.textMessageChunk:
            _handleIncomingTextChunk(json);
          case DataChannelMessage.textMessageEnd:
            _handleIncomingTextEnd(json);
          case DataChannelMessage.securePayload:
            final payload = json['payload'];
            if (payload is Map<String, dynamic>) {
              onSecurePayloadReceived?.call(payload);
            } else if (payload is Map) {
              onSecurePayloadReceived?.call(
                payload.map((key, value) => MapEntry(key.toString(), value)),
              );
            }
          case DataChannelMessage.fileStart:
            onFileStart?.call(json['name'] as String, json['size'] as int);
          case DataChannelMessage.fileEnd:
            onFileEnd?.call(json['name'] as String);
          case DataChannelMessage.fileReceived:
            final fileName = json['name'] as String?;
            if (fileName == _pendingFileAckName &&
                !(_fileReceivedCompleter?.isCompleted ?? true)) {
              _fileReceivedCompleter?.complete();
            }
          case DataChannelMessage.transferComplete:
            _isTransferDone = true;
            onTransferComplete?.call();
          case DataChannelMessage.cancel:
            onCancelled?.call();
          case DataChannelMessage.disconnect:
            onDisconnected?.call();
        }
      } catch (e) {
        logError('WebRtcTransfer: control message error', error: e);
      }
    };
  }

  void _setupDataChannel(RTCDataChannel channel) {
    channel.onMessage = (message) {
      if (message.isBinary) {
        onFileChunkReceived?.call(message.binary);
      }
    };
  }

  Future<void> _waitForBufferDrain() async {
    await _waitForChannelBufferDrain(_dataChannel, threshold: kChunkSize * 4);
  }

  Future<void> _waitForChannelBufferDrain(
    RTCDataChannel? channel, {
    required int threshold,
  }) async {
    while (!_isDisposed &&
        _isChannelOpen(channel) &&
        (channel!.bufferedAmount ?? 0) > threshold) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> _sendControlMessage(String text) async {
    final channel = _controlChannel;
    if (!_isChannelOpen(channel)) {
      throw StateError('Control DataChannel is not open');
    }

    await _waitForChannelBufferDrain(
      channel,
      threshold: kTextMessageChunkSize * 4,
    );
    await channel!.send(RTCDataChannelMessage(text));
  }

  Future<void> _sendChunkedText(Uint8List bytes) async {
    final transferId =
        '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(1 << 32)}';

    await _sendControlMessage(
      jsonEncode({
        'type': DataChannelMessage.textMessageStart,
        'id': transferId,
        'length': bytes.length,
      }),
    );

    for (
      var offset = 0;
      offset < bytes.length;
      offset += kTextMessageChunkSize
    ) {
      final end = math.min(offset + kTextMessageChunkSize, bytes.length);
      final chunk = Uint8List.sublistView(bytes, offset, end);

      await _sendControlMessage(
        jsonEncode({
          'type': DataChannelMessage.textMessageChunk,
          'id': transferId,
          'chunk': base64Encode(chunk),
        }),
      );
    }

    await _sendControlMessage(
      jsonEncode({'type': DataChannelMessage.textMessageEnd, 'id': transferId}),
    );
  }

  void _handleIncomingTextStart(Map<String, dynamic> json) {
    final transferId = json['id'] as String?;
    if (transferId == null || transferId.isEmpty) {
      return;
    }

    _incomingTextTransferId = transferId;
    _incomingTextBytes = BytesBuilder(copy: false);
    _incomingTextLength = json['length'] as int? ?? 0;
  }

  void _handleIncomingTextChunk(Map<String, dynamic> json) {
    final transferId = json['id'] as String?;
    final chunk = json['chunk'] as String?;

    if (transferId == null ||
        chunk == null ||
        transferId != _incomingTextTransferId) {
      return;
    }

    try {
      _incomingTextBytes?.add(base64Decode(chunk));
    } catch (e, s) {
      logError(
        'WebRtcTransfer: failed to decode text chunk',
        error: e,
        stackTrace: s,
      );
      _resetIncomingTextTransfer();
    }
  }

  void _handleIncomingTextEnd(Map<String, dynamic> json) {
    final transferId = json['id'] as String?;
    if (transferId == null || transferId != _incomingTextTransferId) {
      return;
    }

    final bytes = _incomingTextBytes?.toBytes() ?? Uint8List(0);
    if (_incomingTextLength > 0 && bytes.length != _incomingTextLength) {
      logInfo(
        'WebRtcTransfer: text length mismatch '
        '(expected $_incomingTextLength, got ${bytes.length})',
      );
    }

    final text = utf8.decode(bytes, allowMalformed: true);
    _resetIncomingTextTransfer();
    onTextReceived?.call(text);
  }

  void _resetIncomingTextTransfer() {
    _incomingTextTransferId = null;
    _incomingTextBytes = null;
    _incomingTextLength = 0;
  }

  Future<void> _sendDataChunk(Uint8List chunk) async {
    final channel = _dataChannel;
    if (!_isChannelOpen(channel)) {
      throw StateError('Data DataChannel is not open');
    }

    await channel!.send(RTCDataChannelMessage.fromBinary(chunk));
  }

  bool _isChannelOpen(RTCDataChannel? channel) {
    if (_isDisposed || channel == null) {
      return false;
    }

    return channel.state == RTCDataChannelState.RTCDataChannelOpen;
  }

  void _ensureControlChannel() {
    if (!_isChannelOpen(_controlChannel)) {
      throw StateError('Control DataChannel is not initialized or closed');
    }
  }

  void _ensureDataChannel() {
    if (!_isChannelOpen(_dataChannel)) {
      throw StateError('Data DataChannel is not initialized or closed');
    }
  }
}
