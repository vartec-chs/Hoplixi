import 'package:hoplixi/core/utils/smart_converter_base.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';

/// Результат парсинга OTP URI
class OtpUriParseResult {
  final OtpType type;
  final String secret;
  final String? issuer;
  final String? accountName;
  final AlgorithmOtp algorithm;
  final int digits;
  final int period;
  final int? counter;

  const OtpUriParseResult({
    required this.type,
    required this.secret,
    this.issuer,
    this.accountName,
    this.algorithm = AlgorithmOtp.SHA1,
    this.digits = 6,
    this.period = 30,
    this.counter,
  });

  @override
  String toString() {
    return 'OtpUriParseResult('
        'type: $type, '
        'secret: ${secret.substring(0, secret.length > 4 ? 4 : secret.length)}***, '
        'issuer: $issuer, '
        'accountName: $accountName, '
        'algorithm: $algorithm, '
        'digits: $digits, '
        'period: $period, '
        'counter: $counter'
        ')';
  }
}

/// Парсер OTP URI (otpauth://)
///
/// Формат URI:
/// otpauth://TYPE/LABEL?PARAMETERS
///
/// TYPE: totp или hotp
///
/// LABEL: [ISSUER:]ACCOUNT_NAME (URL-encoded)
///
/// PARAMETERS:
/// - secret (обязательный): Base32-encoded секретный ключ
/// - issuer (опциональный): Название сервиса
/// - algorithm (опциональный): SHA1, SHA256, SHA512 (по умолчанию SHA1)
/// - digits (опциональный): 6 или 8 (по умолчанию 6)
/// - period (опциональный): Период в секундах для TOTP (по умолчанию 30)
/// - counter (обязательный для HOTP): Начальное значение счётчика
///
/// Примеры:
/// otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example
/// otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&counter=0
class OtpUriParser {
  static final _smartConverter = SmartConverter();

  /// Парсит OTP URI и возвращает результат
  ///
  /// Возвращает `null` если URI невалидный
  static OtpUriParseResult? parse(String uri) {
    try {
      final parsedUri = Uri.tryParse(uri.trim());
      if (parsedUri == null) return null;

      // Проверяем схему
      if (parsedUri.scheme != 'otpauth') {
        return null;
      }

      // Получаем тип (totp или hotp)
      final typeStr = parsedUri.host.toLowerCase();
      final OtpType type;
      if (typeStr == 'totp') {
        type = OtpType.totp;
      } else if (typeStr == 'hotp') {
        type = OtpType.hotp;
      } else {
        return null;
      }

      // Получаем label (path)
      // Убираем ведущий слэш
      var label = parsedUri.path;
      if (label.startsWith('/')) {
        label = label.substring(1);
      }
      label = Uri.decodeComponent(label);

      // Парсим label: может быть "issuer:account" или просто "account"
      String? issuer;
      String? accountName;

      if (label.contains(':')) {
        final parts = label.split(':');
        issuer = parts.first.trim();
        accountName = parts.sublist(1).join(':').trim();
      } else {
        accountName = label.trim();
      }

      // Получаем параметры
      final params = parsedUri.queryParameters;

      // Secret (обязательный)
      final secretRaw = params['secret'];
      if (secretRaw == null || secretRaw.isEmpty) {
        return null;
      }

      // Нормализуем секрет в Base32
      final secret = _normalizeSecret(secretRaw);

      // Issuer из параметра (имеет приоритет над label)
      if (params.containsKey('issuer') && params['issuer']!.isNotEmpty) {
        issuer = params['issuer'];
      }

      // Algorithm
      final algorithmStr = params['algorithm']?.toUpperCase() ?? 'SHA1';
      final AlgorithmOtp algorithm;
      switch (algorithmStr) {
        case 'SHA256':
          algorithm = AlgorithmOtp.SHA256;
          break;
        case 'SHA512':
          algorithm = AlgorithmOtp.SHA512;
          break;
        case 'SHA1':
        default:
          algorithm = AlgorithmOtp.SHA1;
          break;
      }

      // Digits
      final digitsStr = params['digits'] ?? '6';
      final digits = int.tryParse(digitsStr) ?? 6;

      // Period (только для TOTP)
      final periodStr = params['period'] ?? '30';
      final period = int.tryParse(periodStr) ?? 30;

      // Counter (только для HOTP)
      int? counter;
      if (type == OtpType.hotp) {
        final counterStr = params['counter'] ?? '0';
        counter = int.tryParse(counterStr) ?? 0;
      }

      return OtpUriParseResult(
        type: type,
        secret: secret,
        issuer: issuer,
        accountName: accountName,
        algorithm: algorithm,
        digits: digits,
        period: period,
        counter: counter,
      );
    } catch (e) {
      return null;
    }
  }

  /// Нормализует секрет в Base32
  ///
  /// Использует SmartConverter для автоматического определения формата
  static String _normalizeSecret(String secret) {
    // Очищаем от пробелов и дефисов
    final cleaned = secret.replaceAll(RegExp(r'[\s-]'), '');

    // Пробуем декодировать через SmartConverter
    final result = _smartConverter.toBase32(cleaned);

    // Если обнаружен base32, используем его напрямую (уже в правильном формате)
    if (result['detected'] == 'base32') {
      // Возвращаем очищенный и нормализованный секрет
      return cleaned.toUpperCase().replaceAll('=', '');
    }

    // Иначе используем результат конвертации
    return (result['base32'] ?? cleaned.toUpperCase()).replaceAll('=', '');
  }

  /// Создаёт OTP URI из параметров
  static String generate({
    required OtpType type,
    required String secret,
    String? issuer,
    String? accountName,
    AlgorithmOtp algorithm = AlgorithmOtp.SHA1,
    int digits = 6,
    int period = 30,
    int? counter,
  }) {
    final typeStr = type == OtpType.totp ? 'totp' : 'hotp';

    // Формируем label
    String label = '';
    if (issuer != null && issuer.isNotEmpty) {
      label = Uri.encodeComponent(issuer);
      if (accountName != null && accountName.isNotEmpty) {
        label += ':${Uri.encodeComponent(accountName)}';
      }
    } else if (accountName != null && accountName.isNotEmpty) {
      label = Uri.encodeComponent(accountName);
    }

    // Формируем параметры
    final params = <String, String>{
      'secret': secret.toUpperCase().replaceAll('=', ''),
    };

    if (issuer != null && issuer.isNotEmpty) {
      params['issuer'] = issuer;
    }

    if (algorithm != AlgorithmOtp.SHA1) {
      params['algorithm'] = algorithm.name;
    }

    if (digits != 6) {
      params['digits'] = digits.toString();
    }

    if (type == OtpType.totp && period != 30) {
      params['period'] = period.toString();
    }

    if (type == OtpType.hotp && counter != null) {
      params['counter'] = counter.toString();
    }

    // Собираем URI
    final uri = Uri(
      scheme: 'otpauth',
      host: typeStr,
      path: '/$label',
      queryParameters: params,
    );

    return uri.toString();
  }

  /// Проверяет, является ли строка валидным OTP URI
  static bool isValid(String uri) {
    return parse(uri) != null;
  }
}
