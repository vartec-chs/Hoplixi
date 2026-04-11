import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hoplixi/generated/migration_otp/index.dart'
    show
        MigrationPayload_Algorithm,
        MigrationPayload,
        MigrationPayload_OtpType,
        MigrationPayload_DigitCount;

class OtpData {
  final String name;
  final String issuer;
  final String algorithm;
  final int digits;
  final String type;
  final int counter;
  final String secretBase32;

  OtpData({
    required this.name,
    required this.issuer,
    required this.algorithm,
    required this.digits,
    required this.type,
    required this.counter,
    required this.secretBase32,
  });
}

Uint8List robustBase64Decode(String s) {
  // Если строка содержит '-' или '_' — это base64Url
  final isUrlSafe = s.contains('-') || s.contains('_');
  // Убираем возможный префикс "otpauth-migration://offline?data="
  // (Ожидается, что поступает уже чистая часть data)
  // Нормализуем: удаляем пробелы и newlines
  final clean = s.replaceAll(RegExp(r'\s+'), '');
  // Добавляем паддинг до кратности 4
  var padded = clean;
  final pad = (4 - padded.length % 4) % 4;
  padded += '=' * pad;
  try {
    return isUrlSafe ? base64Url.decode(padded) : base64.decode(padded);
  } catch (e) {
    // Попробуем оба варианта, если первый упал
    try {
      return base64.decode(padded);
    } catch (_) {
      return base64Url.decode(padded);
    }
  }
}

/// --- Base32 (RFC4648, без '=') для показа секретов в привычном виде ---
const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
String base32Encode(Uint8List bytes) {
  final buffer = StringBuffer();
  int i = 0;
  int index = 0;
  int currByte;
  int nextByte;

  while (i < bytes.length) {
    currByte = bytes[i].toUnsigned(8);

    if (index > 3) {
      if ((i + 1) < bytes.length) {
        nextByte = bytes[i + 1].toUnsigned(8);
      } else {
        nextByte = 0;
      }

      final digit = currByte & (0xFF >> index);
      index = (index + 5) % 8;
      final combined = (digit << index) | (nextByte >> (8 - index));
      buffer.write(_base32Alphabet[combined & 0x1F]);
      if (index == 0) {
        i++;
      } else {
        i++;
      }
    } else {
      final digit = (currByte >> (8 - (index + 5))) & 0x1F;
      buffer.write(_base32Alphabet[digit]);
      index = (index + 5) % 8;
      if (index == 0) i++;
    }
  }

  return buffer.toString();
}

/// --- TOTP/HOTP генерация ---
int _dynamicTruncate(Uint8List hmacResult) {
  final off = hmacResult[hmacResult.length - 1] & 0x0f;
  final binary =
      ((hmacResult[off] & 0x7f) << 24) |
      ((hmacResult[off + 1] & 0xff) << 16) |
      ((hmacResult[off + 2] & 0xff) << 8) |
      (hmacResult[off + 3] & 0xff);
  return binary;
}

/// Получить OTP как строку нужной длины
String hotp(Uint8List secret, int counter, int digits, String algo) {
  // counter -> 8 байт big-endian
  final counterBytes = Uint8List(8);
  for (int i = 7; i >= 0; i--) {
    counterBytes[i] = (counter & 0xff);
    counter >>= 8;
  }

  Hmac hmac;
  final key = secret;
  switch (algo) {
    case 'SHA1':
      hmac = Hmac(sha1, key);
      break;
    case 'SHA256':
      hmac = Hmac(sha256, key);
      break;
    case 'SHA512':
      hmac = Hmac(sha512, key);
      break;
    default:
      hmac = Hmac(sha1, key);
  }

  final mac = hmac.convert(counterBytes).bytes;
  final binary = _dynamicTruncate(Uint8List.fromList(mac));
  final otpInt = binary % pow(10, digits) as int;
  return otpInt.toString().padLeft(digits, '0');
}

String totp(
  Uint8List secret, {
  int digits = 6,
  int period = 30,
  String algo = 'SHA1',
}) {
  final secondsSinceEpoch =
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final counter = secondsSinceEpoch ~/ period;
  return hotp(secret, counter, digits, algo);
}

/// --- Основная функция: принимает otpauth-migration ссылку или чистый base64 data ---
List<OtpData> parseMigrationUri(String input) {
  // Попробуем распарсить как URI, и извлечь параметр data, иначе — берем вход как base64
  String? b64;
  try {
    final uri = Uri.parse(input);
    // Форматы:
    // 1) otpauth-migration://offline?data=BASE64
    // 2) otpauth-migration://offline/BASE64
    if (uri.queryParameters.containsKey('data')) {
      b64 = uri.queryParameters['data'];
    } else if (uri.pathSegments.isNotEmpty) {
      // path может быть '/BASE64'
      b64 = uri.pathSegments.join('/');
      if (b64.contains('data=')) {
        // на всякий случай
        final maybe = b64.split('data=').last;
        b64 = maybe;
      }
    } else {
      // может быть сам base64
      if (input.contains('://')) {
        // попытка взять после '?'
        final qIndex = input.indexOf('?');
        if (qIndex >= 0 && qIndex + 1 < input.length) {
          final qpart = input.substring(qIndex + 1);
          final params = Uri.splitQueryString(qpart, encoding: utf8);
          if (params.containsKey('data')) b64 = params['data'];
        }
      }
    }
  } catch (_) {
    // не URI — будем считать, что это base64
  }

  b64 ??= input;

  final bytes = robustBase64Decode(b64);

  // Парсим protobuf
  final payload = MigrationPayload.fromBuffer(bytes);

  final otpParameters = <OtpData>[];
  for (final otp in payload.otpParameters) {
    final secretBytes = otp.secret;
    final name = otp.hasName() ? otp.name : '';
    final issuer = otp.hasIssuer() ? otp.issuer : '';
    final algorithm = (() {
      switch (otp.algorithm) {
        case MigrationPayload_Algorithm.ALGORITHM_SHA1:
          return 'SHA1';
        case MigrationPayload_Algorithm.ALGORITHM_SHA256:
          return 'SHA256';
        case MigrationPayload_Algorithm.ALGORITHM_SHA512:
          return 'SHA512';
        case MigrationPayload_Algorithm.ALGORITHM_MD5:
          return 'MD5';
        default:
          return 'SHA1';
      }
    })();
    final digits = (() {
      switch (otp.digits) {
        case MigrationPayload_DigitCount.DIGIT_COUNT_EIGHT:
          return 8;
        case MigrationPayload_DigitCount.DIGIT_COUNT_SIX:
        default:
          return 6;
      }
    })();
    final type = (() {
      switch (otp.type) {
        case MigrationPayload_OtpType.OTP_TYPE_HOTP:
          return 'HOTP';
        case MigrationPayload_OtpType.OTP_TYPE_TOTP:
        default:
          return 'TOTP';
      }
    })();
    final counter = (otp.hasCounter() ? otp.counter : 0) as int;

    final secretBase32 = base32Encode(Uint8List.fromList(secretBytes));

    otpParameters.add(
      OtpData(
        name: name,
        issuer: issuer,
        algorithm: algorithm,
        digits: digits,
        type: type,
        counter: counter,
        secretBase32: secretBase32,
      ),
    );
  }

  return otpParameters;
}

Uint8List base32Decode(String base32) {
  final clean = base32.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
  final length = clean.length;
  final bytes = <int>[];
  int buffer = 0;
  int bitsLeft = 0;

  for (int i = 0; i < length; i++) {
    final char = clean[i];
    final val = _base32Alphabet.indexOf(char);
    if (val < 0) continue;

    buffer = (buffer << 5) | val;
    bitsLeft += 5;

    if (bitsLeft >= 8) {
      bytes.add((buffer >> (bitsLeft - 8)) & 0xFF);
      bitsLeft -= 8;
    }
  }
  return Uint8List.fromList(bytes);
}
