import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

class BankCardNfcReadResult {
  const BankCardNfcReadResult({
    this.cardNumber,
    this.cardholderName,
    this.expiryMonth,
    this.expiryYear,
    this.applicationLabel,
    this.primaryAid,
    this.cardNetwork,
  });

  final String? cardNumber;
  final String? cardholderName;
  final String? expiryMonth;
  final String? expiryYear;
  final String? applicationLabel;
  final String? primaryAid;
  final String? cardNetwork;

  bool get hasReadableData =>
      _isNotBlank(cardNumber) ||
      _isNotBlank(cardholderName) ||
      _isNotBlank(expiryMonth) ||
      _isNotBlank(expiryYear) ||
      _isNotBlank(applicationLabel) ||
      _isNotBlank(cardNetwork);

  String? get last4Digits {
    final value = cardNumber;
    if (!_isNotBlank(value)) {
      return null;
    }
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return null;
    }
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }

  List<String> buildReadableSummary() {
    final lines = <String>[];
    if (_isNotBlank(cardNumber)) {
      lines.add('Номер: ${_maskCardNumber(cardNumber!)}');
    }
    if (_isNotBlank(expiryMonth) && _isNotBlank(expiryYear)) {
      lines.add('Срок: ${expiryMonth!.padLeft(2, '0')}/${expiryYear!}');
    }
    if (_isNotBlank(cardholderName)) {
      lines.add('Держатель: ${cardholderName!}');
    }
    if (_isNotBlank(cardNetwork)) {
      lines.add('Сеть: ${_humanizeNetwork(cardNetwork!)}');
    } else if (_isNotBlank(applicationLabel)) {
      lines.add('Приложение: ${applicationLabel!}');
    }
    return lines;
  }

  static String _maskCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) {
      return digits;
    }
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  static String _humanizeNetwork(String value) {
    return switch (value) {
      'visa' => 'Visa',
      'mastercard' => 'Mastercard',
      'amex' => 'American Express',
      'discover' => 'Discover',
      'dinersclub' => 'Diners Club',
      'jcb' => 'JCB',
      'unionpay' => 'UnionPay',
      _ => value,
    };
  }

  static bool _isNotBlank(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class BankCardNfcReaderService {
  static const String _ppseName = '2PAY.SYS.DDF01';
  static const List<String> _fallbackAidHexes = [
    'A0000000031010',
    'A0000000032010',
    'A0000000041010',
    'A0000000043060',
    'A00000002501',
    'A0000001523010',
    'A0000000651010',
    'A000000333010101',
    'A0000006581010',
  ];

  Future<BankCardNfcReadResult> readCard() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw StateError(switch (availability) {
        NfcAvailability.disabled => 'NFC выключен на устройстве.',
        NfcAvailability.unsupported => 'Устройство не поддерживает NFC.',
        _ => 'NFC временно недоступен.',
      });
    }

    final completer = Completer<BankCardNfcReadResult>();
    var sessionCompleted = false;

    Future<void> completeSession({
      BankCardNfcReadResult? result,
      Object? error,
      StackTrace? stackTrace,
    }) async {
      if (sessionCompleted) {
        return;
      }
      sessionCompleted = true;

      try {
        if (error != null) {
          await NfcManager.instance.stopSession(
            errorMessageIos: 'Не удалось прочитать банковскую карту.',
          );
        } else {
          await NfcManager.instance.stopSession(
            alertMessageIos: 'Чтение банковской карты завершено.',
          );
        }
      } catch (_) {}

      if (error != null) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        return;
      }

      if (!completer.isCompleted) {
        completer.complete(result!);
      }
    }

    await NfcManager.instance.startSession(
      pollingOptions: const {NfcPollingOption.iso14443},
      alertMessageIos: 'Поднесите банковскую карту к устройству.',
      onSessionErrorIos: (error) {
        if (sessionCompleted || completer.isCompleted) {
          return;
        }
        completer.completeError(StateError(error.message));
      },
      onDiscovered: (tag) async {
        try {
          final result = await _readTag(tag);
          await completeSession(result: result);
        } catch (error, stackTrace) {
          await completeSession(error: error, stackTrace: stackTrace);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () =>
          throw TimeoutException('Время ожидания NFC-карты истекло.'),
    );
  }

  Future<BankCardNfcReadResult> _readTag(NfcTag tag) async {
    final transceiver = _resolveTransceiver(tag);
    if (transceiver == null) {
      throw StateError(
        'Карта не поддерживает ISO-DEP/ISO7816 через nfc_manager.',
      );
    }

    final aidCandidates = await _discoverAidCandidates(transceiver);
    final resolvedAidCandidates = aidCandidates.isNotEmpty
        ? aidCandidates
        : _fallbackAidHexes.map(_hexToBytes).toList(growable: false);

    BankCardNfcReadResult? bestResult;
    for (final aid in resolvedAidCandidates) {
      final result = await _readApplication(transceiver, aid);
      if (result.hasReadableData) {
        return result;
      }
      bestResult ??= result;
    }

    if (bestResult?.hasReadableData == true) {
      return bestResult!;
    }

    throw StateError('Не удалось извлечь EMV-данные с карты.');
  }

  Future<List<Uint8List>> _discoverAidCandidates(
    _ApduTransceiver transceiver,
  ) async {
    final response = await transceiver.transceive(
      _buildCommand(
        cla: 0x00,
        ins: 0xA4,
        p1: 0x04,
        p2: 0x00,
        data: Uint8List.fromList(_ppseName.codeUnits),
      ),
    );

    if (!response.isSuccess) {
      return const [];
    }

    final aids = <String>{};
    final nodes = _parseTlv(response.data);
    for (final aidBytes in _findAllTag(nodes, '4F')) {
      final aidHex = _bytesToHex(aidBytes);
      if (aidHex.isNotEmpty) {
        aids.add(aidHex);
      }
    }

    return aids.map(_hexToBytes).toList(growable: false);
  }

  Future<BankCardNfcReadResult> _readApplication(
    _ApduTransceiver transceiver,
    Uint8List aid,
  ) async {
    final selectResponse = await transceiver.transceive(
      _buildCommand(cla: 0x00, ins: 0xA4, p1: 0x04, p2: 0x00, data: aid),
    );

    if (!selectResponse.isSuccess) {
      return const BankCardNfcReadResult();
    }

    final selectNodes = _parseTlv(selectResponse.data);
    final applicationLabel = _decodeText(
      _findFirstTag(selectNodes, '50') ?? _findFirstTag(selectNodes, '9F12'),
    );
    final pdol = _findFirstTag(selectNodes, '9F38');
    final requestedNetwork = _detectNetwork(
      aid: _bytesToHex(aid),
      label: applicationLabel,
    );

    final gpoResponse = await transceiver.transceive(_buildGpoCommand(pdol));
    if (!gpoResponse.isSuccess) {
      return BankCardNfcReadResult(
        applicationLabel: applicationLabel,
        primaryAid: _bytesToHex(aid),
        cardNetwork: requestedNetwork,
      );
    }

    final afl = _extractAfl(gpoResponse.data);
    if (afl.isEmpty) {
      return BankCardNfcReadResult(
        applicationLabel: applicationLabel,
        primaryAid: _bytesToHex(aid),
        cardNetwork: requestedNetwork,
      );
    }

    final recordPayloads = <Uint8List>[];
    for (final descriptor in afl) {
      for (
        var recordNumber = descriptor.firstRecord;
        recordNumber <= descriptor.lastRecord;
        recordNumber++
      ) {
        final response = await transceiver.transceive(
          _buildCommand(
            cla: 0x00,
            ins: 0xB2,
            p1: recordNumber,
            p2: (descriptor.sfi << 3) | 0x04,
            data: Uint8List(0),
          ),
        );

        if (response.isSuccess && response.data.isNotEmpty) {
          recordPayloads.add(response.data);
        }
      }
    }

    final parsedRecords = recordPayloads
        .expand(_parseTlv)
        .toList(growable: false);
    final pan = _extractPan(parsedRecords);
    final expiry = _extractExpiry(parsedRecords);
    final cardholderName = _sanitizeCardholderName(
      _decodeText(_findFirstTag(parsedRecords, '5F20')),
    );

    return BankCardNfcReadResult(
      cardNumber: pan,
      cardholderName: cardholderName,
      expiryMonth: expiry?.$1,
      expiryYear: expiry?.$2,
      applicationLabel: applicationLabel,
      primaryAid: _bytesToHex(aid),
      cardNetwork: requestedNetwork,
    );
  }

  _ApduTransceiver? _resolveTransceiver(NfcTag tag) {
    final isoDep = IsoDepAndroid.from(tag);
    if (isoDep != null) {
      return _ApduTransceiver(
        transceive: (apdu) async =>
            _ApduResponse.fromRaw(await isoDep.transceive(apdu)),
      );
    }

    final iso7816 = Iso7816Ios.from(tag);
    if (iso7816 != null) {
      return _ApduTransceiver(
        transceive: (apdu) async {
          final response = await iso7816.sendCommandRaw(data: apdu);
          return _ApduResponse(
            data: response.payload,
            sw1: response.statusWord1,
            sw2: response.statusWord2,
          );
        },
      );
    }

    final miFare = MiFareIos.from(tag);
    if (miFare != null) {
      return _ApduTransceiver(
        transceive: (apdu) async {
          final response = await miFare.sendMiFareIso7816CommandRaw(data: apdu);
          return _ApduResponse(
            data: response.payload,
            sw1: response.statusWord1,
            sw2: response.statusWord2,
          );
        },
      );
    }

    return null;
  }

  Uint8List _buildGpoCommand(Uint8List? pdol) {
    final pdolData = _buildPdolData(pdol);
    final commandData = Uint8List.fromList([
      0x83,
      pdolData.length,
      ...pdolData,
    ]);
    return _buildCommand(
      cla: 0x80,
      ins: 0xA8,
      p1: 0x00,
      p2: 0x00,
      data: commandData,
    );
  }

  Uint8List _buildPdolData(Uint8List? pdol) {
    if (pdol == null || pdol.isEmpty) {
      return Uint8List(0);
    }

    final descriptors = _parseDol(pdol);
    final totalLength = descriptors.fold<int>(
      0,
      (sum, descriptor) => sum + descriptor.length,
    );
    return Uint8List(totalLength);
  }

  List<_DolDescriptor> _parseDol(Uint8List bytes) {
    final descriptors = <_DolDescriptor>[];
    var offset = 0;
    while (offset < bytes.length) {
      final (tag, nextOffset) = _readTlvTag(bytes, offset);
      offset = nextOffset;
      if (offset >= bytes.length) {
        break;
      }
      descriptors.add(_DolDescriptor(tag: tag, length: bytes[offset]));
      offset += 1;
    }
    return descriptors;
  }

  List<_AflDescriptor> _extractAfl(Uint8List gpoData) {
    if (gpoData.isEmpty) {
      return const [];
    }

    Uint8List aflBytes = Uint8List(0);
    if (gpoData.first == 0x80 && gpoData.length >= 4) {
      aflBytes = gpoData.sublist(4);
    } else {
      final nodes = _parseTlv(gpoData);
      aflBytes = _findFirstTag(nodes, '94') ?? Uint8List(0);
    }

    final descriptors = <_AflDescriptor>[];
    for (var i = 0; i + 3 < aflBytes.length; i += 4) {
      descriptors.add(
        _AflDescriptor(
          sfi: aflBytes[i] >> 3,
          firstRecord: aflBytes[i + 1],
          lastRecord: aflBytes[i + 2],
        ),
      );
    }
    return descriptors;
  }

  String? _extractPan(List<_TlvNode> nodes) {
    final panFrom5A = _decodeBcd(_findFirstTag(nodes, '5A'));
    if (_isNotBlank(panFrom5A)) {
      return panFrom5A;
    }

    final track2 = _decodeBcd(_findFirstTag(nodes, '57'));
    if (!_isNotBlank(track2)) {
      return null;
    }

    final separatorIndex = track2!.indexOf('D');
    if (separatorIndex <= 0) {
      return null;
    }
    return track2.substring(0, separatorIndex);
  }

  (String, String)? _extractExpiry(List<_TlvNode> nodes) {
    final raw5f24 = _decodeBcd(_findFirstTag(nodes, '5F24'));
    if (_isNotBlank(raw5f24) && raw5f24!.length >= 4) {
      final year = '20${raw5f24.substring(0, 2)}';
      final month = raw5f24.substring(2, 4);
      return (month, year);
    }

    final track2 = _decodeBcd(_findFirstTag(nodes, '57'));
    if (!_isNotBlank(track2)) {
      return null;
    }
    final separatorIndex = track2!.indexOf('D');
    if (separatorIndex < 0 || track2.length < separatorIndex + 5) {
      return null;
    }
    final yyMm = track2.substring(separatorIndex + 1, separatorIndex + 5);
    return (yyMm.substring(2, 4), '20${yyMm.substring(0, 2)}');
  }

  List<_TlvNode> _parseTlv(Uint8List bytes) {
    final nodes = <_TlvNode>[];
    var offset = 0;
    while (offset < bytes.length) {
      final (tag, afterTagOffset) = _readTlvTag(bytes, offset);
      final (length, afterLengthOffset) = _readTlvLength(bytes, afterTagOffset);
      if (afterLengthOffset + length > bytes.length) {
        break;
      }
      final value = bytes.sublist(
        afterLengthOffset,
        afterLengthOffset + length,
      );
      final isConstructed = (bytes[offset] & 0x20) == 0x20;
      nodes.add(
        _TlvNode(
          tag: tag,
          value: value,
          children: isConstructed ? _parseTlv(value) : const [],
        ),
      );
      offset = afterLengthOffset + length;
    }
    return nodes;
  }

  Uint8List? _findFirstTag(List<_TlvNode> nodes, String tag) {
    for (final node in nodes) {
      if (node.tag == tag) {
        return node.value;
      }
      final nested = _findFirstTag(node.children, tag);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  List<Uint8List> _findAllTag(List<_TlvNode> nodes, String tag) {
    final matches = <Uint8List>[];
    for (final node in nodes) {
      if (node.tag == tag) {
        matches.add(node.value);
      }
      matches.addAll(_findAllTag(node.children, tag));
    }
    return matches;
  }

  (String, int) _readTlvTag(Uint8List bytes, int offset) {
    final buffer = <int>[bytes[offset]];
    offset += 1;
    if ((buffer.first & 0x1F) == 0x1F) {
      while (offset < bytes.length) {
        final next = bytes[offset];
        buffer.add(next);
        offset += 1;
        if ((next & 0x80) == 0) {
          break;
        }
      }
    }
    return (_bytesToHex(Uint8List.fromList(buffer)), offset);
  }

  (int, int) _readTlvLength(Uint8List bytes, int offset) {
    final first = bytes[offset];
    offset += 1;
    if (first < 0x80) {
      return (first, offset);
    }

    final byteCount = first & 0x7F;
    var length = 0;
    for (var i = 0; i < byteCount; i++) {
      length = (length << 8) | bytes[offset];
      offset += 1;
    }
    return (length, offset);
  }

  Uint8List _buildCommand({
    required int cla,
    required int ins,
    required int p1,
    required int p2,
    required Uint8List data,
  }) {
    return Uint8List.fromList([cla, ins, p1, p2, data.length, ...data, 0x00]);
  }

  String _bytesToHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  Uint8List _hexToBytes(String hex) {
    final normalized = hex.replaceAll(RegExp(r'\s+'), '');
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  String? _decodeText(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final value = String.fromCharCodes(
      bytes,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    return value.isEmpty ? null : value;
  }

  String? _sanitizeCardholderName(String? value) {
    if (!_isNotBlank(value)) {
      return null;
    }
    return value!.replaceAll('/', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _decodeBcd(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final buffer = StringBuffer();
    for (final byte in bytes) {
      final high = (byte >> 4) & 0x0F;
      final low = byte & 0x0F;

      if (high <= 9) {
        buffer.write(high);
      } else if (high == 0x0D) {
        buffer.write('D');
      }

      if (low <= 9) {
        buffer.write(low);
      } else if (low == 0x0D) {
        buffer.write('D');
      }
    }

    final value = buffer.toString().replaceAll(
      RegExp(r'F+$', caseSensitive: false),
      '',
    );
    return value.isEmpty ? null : value;
  }

  String? _detectNetwork({required String aid, String? label}) {
    final normalizedAid = aid.toUpperCase();
    final normalizedLabel = (label ?? '').toLowerCase();

    if (normalizedAid.startsWith('A000000003') ||
        normalizedLabel.contains('visa')) {
      return 'visa';
    }
    if (normalizedAid.startsWith('A000000004') ||
        normalizedLabel.contains('mastercard') ||
        normalizedLabel.contains('maestro')) {
      return 'mastercard';
    }
    if (normalizedAid.startsWith('A000000025') ||
        normalizedLabel.contains('american express') ||
        normalizedLabel.contains('amex')) {
      return 'amex';
    }
    if (normalizedAid.startsWith('A000000152') ||
        normalizedLabel.contains('discover')) {
      return 'discover';
    }
    if (normalizedLabel.contains('diners')) {
      return 'dinersclub';
    }
    if (normalizedAid.startsWith('A000000065') ||
        normalizedLabel.contains('jcb')) {
      return 'jcb';
    }
    if (normalizedAid.startsWith('A000000333') ||
        normalizedLabel.contains('unionpay')) {
      return 'unionpay';
    }
    return null;
  }

  bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
}

class _ApduTransceiver {
  const _ApduTransceiver({required this.transceive});

  final Future<_ApduResponse> Function(Uint8List apdu) transceive;
}

class _ApduResponse {
  const _ApduResponse({
    required this.data,
    required this.sw1,
    required this.sw2,
  });

  factory _ApduResponse.fromRaw(Uint8List raw) {
    if (raw.length < 2) {
      throw StateError('APDU response is too short.');
    }
    return _ApduResponse(
      data: raw.sublist(0, raw.length - 2),
      sw1: raw[raw.length - 2],
      sw2: raw[raw.length - 1],
    );
  }

  final Uint8List data;
  final int sw1;
  final int sw2;

  bool get isSuccess => sw1 == 0x90 && sw2 == 0x00;
}

class _TlvNode {
  const _TlvNode({
    required this.tag,
    required this.value,
    required this.children,
  });

  final String tag;
  final Uint8List value;
  final List<_TlvNode> children;
}

class _DolDescriptor {
  const _DolDescriptor({required this.tag, required this.length});

  final String tag;
  final int length;
}

class _AflDescriptor {
  const _AflDescriptor({
    required this.sfi,
    required this.firstRecord,
    required this.lastRecord,
  });

  final int sfi;
  final int firstRecord;
  final int lastRecord;
}
