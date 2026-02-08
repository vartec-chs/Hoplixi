import 'dart:convert';
import 'dart:typed_data';

class SmartConverter {
  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Главная функция — принимает строку (может содержать пробелы/переносы),
  /// возвращает Map с detected: 'base64'|'base32'|'plain' и base32: <строка>
  Map<String, String> toBase32(String input) {
    final cleaned = _cleanInput(input);

    // Try to decide by strongest heuristics + tentativa декодирования
    final base64Candidate = _isBase64Like(cleaned);
    final base32Candidate = _isBase32Like(cleaned);

    Uint8List? bytesFromBase64;
    Uint8List? bytesFromBase32;

    if (base64Candidate) {
      try {
        bytesFromBase64 = base64.decode(_padBase64(cleaned));
      } catch (e) {
        bytesFromBase64 = null;
      }
    }

    if (base32Candidate) {
      try {
        bytesFromBase32 = _base32Decode(cleaned);
      } catch (e) {
        bytesFromBase32 = null;
      }
    }

    String detected;
    Uint8List bytes;

    // If both decodings succeeded, try to disambiguate by re-encoding and comparing
    if (bytesFromBase64 != null && bytesFromBase32 != null) {
      final reBase32FromB64 = _base32Encode(bytesFromBase64, addPadding: true);
      final normalizedInput = _normalizeBase32ForCompare(cleaned);
      final normalizedRe = _normalizeBase32ForCompare(reBase32FromB64);
      if (normalizedInput == normalizedRe) {
        detected = 'base64';
        bytes = bytesFromBase64;
      } else {
        // try other direction
        final reBase32FromB32 = _base32Encode(
          bytesFromBase32,
          addPadding: true,
        );
        final normalizedRe2 = _normalizeBase32ForCompare(reBase32FromB32);
        if (normalizedInput == normalizedRe2) {
          detected = 'base32';
          bytes = bytesFromBase32;
        } else {
          // ambiguous: prefer base64 if it contains '+' or '/' or '=' padding originally
          if (cleaned.contains('+') ||
              cleaned.contains('/') ||
              input.contains('=')) {
            detected = 'base64';
            bytes = bytesFromBase64;
          } else {
            detected = 'base32';
            bytes = bytesFromBase32;
          }
        }
      }
    } else if (bytesFromBase64 != null) {
      detected = 'base64';
      bytes = bytesFromBase64;
    } else if (bytesFromBase32 != null) {
      detected = 'base32';
      bytes = bytesFromBase32;
    } else {
      // treat as plain text (UTF-8)
      detected = 'plain';
      bytes = Uint8List.fromList(utf8.encode(input));
    }

    final outBase32 = _base32Encode(bytes, addPadding: true);
    return {'detected': detected, 'base32': outBase32};
  }

  // -------------------- Helpers --------------------

  String _cleanInput(String s) {
    // remove whitespace and common separators
    return s.replaceAll(RegExp(r'\s+'), '');
  }

  bool _isBase64Like(String s) {
    if (s.isEmpty) return false;
    // base64 charset: A-Z a-z 0-9 + / and optional =
    final re = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return re.hasMatch(s);
  }

  bool _isBase32Like(String s) {
    if (s.isEmpty) return false;
    // RFC4648 Base32: A-Z2-7 and = padding; case-insensitive
    final re = RegExp(r'^[A-Za-z2-7]+={0,8}$');
    return re.hasMatch(s);
  }

  String _padBase64(String s) {
    // dart base64.decode tolerates missing padding, but ensure it's padded to length%4==0
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s + '=' * (4 - mod);
  }

  String _normalizeBase32ForCompare(String s) {
    final cleaned = s.replaceAll('=', '').toUpperCase();
    return cleaned;
  }

  // -------------------- Base32 encode/decode (RFC4648) --------------------

  String _base32Encode(Uint8List data, {bool addPadding = true}) {
    if (data.isEmpty) return addPadding ? '' : '';
    final buffer = StringBuffer();
    int index = 0;
    int currByte;
    int nextByte;
    int digit;
    int i = 0;

    while (i < data.length) {
      // take five-bit groups across bytes
      currByte = data[i] & 0xFF;
      // 1) first char
      digit = (currByte >> 3) & 0x1F;
      buffer.write(_base32Alphabet[digit]);

      // 2) second char
      digit = (currByte & 0x07) << 2;
      if (i + 1 < data.length) {
        nextByte = data[i + 1] & 0xFF;
        digit |= (nextByte >> 6) & 0x03;
        buffer.write(_base32Alphabet[digit]);

        // 3) third char
        digit = (nextByte >> 1) & 0x1F;
        buffer.write(_base32Alphabet[digit]);

        // 4) fourth char
        digit = (nextByte & 0x01) << 4;
        if (i + 2 < data.length) {
          final third = data[i + 2] & 0xFF;
          digit |= (third >> 4) & 0x0F;
          buffer.write(_base32Alphabet[digit]);

          // 5) fifth char
          digit = (third & 0x0F) << 1;
          if (i + 3 < data.length) {
            final fourth = data[i + 3] & 0xFF;
            digit |= (fourth >> 7) & 0x01;
            buffer.write(_base32Alphabet[digit]);

            // 6) sixth char
            digit = (fourth >> 2) & 0x1F;
            buffer.write(_base32Alphabet[digit]);

            // 7) seventh char
            digit = (fourth & 0x03) << 3;
            if (i + 4 < data.length) {
              final fifth = data[i + 4] & 0xFF;
              digit |= (fifth >> 5) & 0x07;
              buffer.write(_base32Alphabet[digit]);

              // 8) eighth char
              digit = fifth & 0x1F;
              buffer.write(_base32Alphabet[digit]);
            } else {
              buffer.write(_base32Alphabet[digit]);
              if (addPadding) {
                buffer.write('='); // pad 7th produced, 8th missing
              }
            }
          } else {
            buffer.write(_base32Alphabet[digit]);
            if (addPadding) buffer.write('=='); // pad for 6/7/8
          }
        } else {
          buffer.write(_base32Alphabet[digit]);
          if (addPadding) buffer.write('===='); // pad for 5..8
        }
        i += 3;
      } else {
        buffer.write(_base32Alphabet[digit]);
        if (addPadding) buffer.write('======'); // pad remaining
        i += 1;
      }
    }

    // The above loop overproduces when adding inside; however the RFC grouping is easier done with bitbuffer approach.
    // Simpler and robust alternative: implement a bit-accumulator.

    // We'll fallback — implement bit-accumulator for correctness:
    return _base32EncodeBitAcc(data, addPadding: addPadding);
  }

  String _base32EncodeBitAcc(Uint8List data, {bool addPadding = true}) {
    if (data.isEmpty) return '';
    final buffer = StringBuffer();
    int index = 0;
    int curr = 0;
    int bitsLeft = 0;

    for (final byte in data) {
      curr = (curr << 8) | (byte & 0xFF);
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        final val = (curr >> bitsLeft) & 0x1F;
        buffer.write(_base32Alphabet[val]);
      }
    }
    if (bitsLeft > 0) {
      final val = (curr << (5 - bitsLeft)) & 0x1F;
      buffer.write(_base32Alphabet[val]);
    }

    if (addPadding) {
      // pad to multiple of 8 chars
      final padNeeded = (8 - (buffer.length % 8)) % 8;
      for (var i = 0; i < padNeeded; i++) {
        buffer.write('=');
      }
    }

    return buffer.toString();
  }

  Uint8List _base32Decode(String input) {
    if (input.isEmpty) return Uint8List(0);
    final cleaned = input.replaceAll('=', '').toUpperCase();
    // map chars to values
    final values = <int>[];
    for (var i = 0; i < cleaned.length; i++) {
      final ch = cleaned.codeUnitAt(i);
      final idx = _base32Alphabet.indexOf(String.fromCharCode(ch));
      if (idx == -1) {
        throw FormatException(
          'Invalid Base32 character: ${String.fromCharCode(ch)}',
        );
      }
      values.add(idx);
    }

    final out = <int>[];
    int buffer = 0;
    int bitsLeft = 0;
    for (final val in values) {
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        final byte = (buffer >> bitsLeft) & 0xFF;
        out.add(byte);
      }
    }

    return Uint8List.fromList(out);
  }
}

// -------------------- Примеры / тесты --------------------

// void main() {
//   final conv = SmartConverter();

//   // Пример: обычный текст
//   final r1 = conv.toBase32('Hello, world!');
//   print('detected=${r1['detected']}, base32=${r1['base32']}');

//   // Пример: Base64 вход
//   final b64 = base64.encode(utf8.encode('Hello, world!'));
//   final r2 = conv.toBase32(b64);
//   print('orig base64: $b64');
//   print('detected=${r2['detected']}, base32=${r2['base32']}');

//   // Пример: Base32 вход (the same result)
//   final base32Text = r2['base32']!;
//   final r3 = conv.toBase32(base32Text);
//   print('orig base32: $base32Text');
//   print('detected=${r3['detected']}, base32=${r3['base32']}');
// }
