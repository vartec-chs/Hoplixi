import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/index.dart';

/// Размер чанка для передачи файлов (16 KB).
const int kChunkSize = 16 * 1024;

/// Типы control-сообщений через DataChannel.
class DataChannelMessage {
  static const String fileStart = 'file_start';
  static const String fileEnd = 'file_end';
  static const String textMessage = 'text_message';
  static const String transferComplete = 'transfer_complete';
  static const String cancel = 'cancel';
}

/// Сервис для P2P-передачи файлов и текста
/// через WebRTC DataChannel.
class WebRtcTransferService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _controlChannel;
  RTCDataChannel? _dataChannel;

  /// Флаг: соединение уже было установлено.
  /// Предотвращает повторный вызов [onConnected]
  /// при переходах ICE Connected → Completed → Connected.
  bool _hasConnected = false;

  /// Флаг: передача завершена (отправлен или получен
  /// `transfer_complete`). После этого ICE-ошибки
  /// игнорируются, т.к. Disconnected/Failed — нормальное
  /// поведение при закрытии соединения.
  bool _isTransferDone = false;

  // ── Колбэки ──

  /// Вызывается при получении текстового сообщения.
  void Function(String text)? onTextReceived;

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

    final message = jsonEncode({
      'type': DataChannelMessage.textMessage,
      'text': text,
    });
    _controlChannel!.send(RTCDataChannelMessage(message));
  }

  /// Отправляет один файл через DataChannel.
  ///
  /// Прогресс отправки обновляется через [onProgress].
  Future<void> sendFile(File file) async {
    _ensureControlChannel();
    _ensureDataChannel();

    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();

    // Уведомляем о начале файла.
    final startMsg = jsonEncode({
      'type': DataChannelMessage.fileStart,
      'name': fileName,
      'size': fileSize,
    });
    _controlChannel!.send(RTCDataChannelMessage(startMsg));

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

        _dataChannel!.send(RTCDataChannelMessage.fromBinary(subChunk));
        bytesSent += subChunk.length;
        onProgress?.call(bytesSent, fileSize);

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
    _controlChannel!.send(RTCDataChannelMessage(endMsg));

    logInfo('WebRtcTransfer: file sent: $fileName ($fileSize bytes)');
  }

  /// Уведомляет удалённую сторону о завершении передачи.
  void sendTransferComplete() {
    if (_controlChannel == null) return;

    _isTransferDone = true;
    try {
      final msg = jsonEncode({'type': DataChannelMessage.transferComplete});
      _controlChannel!.send(RTCDataChannelMessage(msg));
    } catch (e) {
      logError('WebRtcTransfer: sendTransferComplete error', error: e);
    }
  }

  /// Отменяет передачу.
  void cancelTransfer() {
    if (_controlChannel == null) return;

    try {
      final msg = jsonEncode({'type': DataChannelMessage.cancel});
      _controlChannel!.send(RTCDataChannelMessage(msg));
    } catch (e) {
      logError('WebRtcTransfer: cancelTransfer error', error: e);
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

    final control = _controlChannel;
    final data = _dataChannel;
    final peer = _peerConnection;

    _controlChannel = null;
    _dataChannel = null;
    _peerConnection = null;

    try {
      await control?.close();
    } catch (_) {}

    try {
      await data?.close();
    } catch (_) {}

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
    onFileStart = null;
    onFileChunkReceived = null;
    onFileEnd = null;
    onProgress = null;
    onTransferComplete = null;
    onCancelled = null;
    onLocalIceCandidate = null;
    onConnected = null;
    onError = null;
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
          case DataChannelMessage.fileStart:
            onFileStart?.call(json['name'] as String, json['size'] as int);
          case DataChannelMessage.fileEnd:
            onFileEnd?.call(json['name'] as String);
          case DataChannelMessage.transferComplete:
            _isTransferDone = true;
            onTransferComplete?.call();
          case DataChannelMessage.cancel:
            onCancelled?.call();
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
    while (_dataChannel != null &&
        (_dataChannel!.bufferedAmount ?? 0) > kChunkSize * 4) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void _ensureControlChannel() {
    if (_controlChannel == null) {
      throw StateError('Control DataChannel is not initialized');
    }
  }

  void _ensureDataChannel() {
    if (_dataChannel == null) {
      throw StateError('Data DataChannel is not initialized');
    }
  }
}
