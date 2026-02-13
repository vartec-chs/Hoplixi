import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/services/local_auth_failure.dart';
import 'package:hoplixi/core/services/local_auth_service.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_key.dart';
import 'pref_category.dart';
import 'storage_errors.dart';

/// Унифицированный сервис для работы с настройками приложения
///
/// Автоматически выбирает хранилище на основе флага [AppKey.isProtected]:
/// - isProtected = true → FlutterSecureStorage (защищённое хранилище)
/// - isProtected = false → SharedPreferences (обычное хранилище)
///
/// Если [AppKey.biometricProtect] = true и biometric_enabled включён,
/// при изменении значения требуется подтверждение биометрией.
class AppStorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthService? _localAuthService;

  /// Ключ для проверки, включена ли биометрия
  static const _biometricEnabledKey = 'biometric_enabled';

  AppStorageService({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
    LocalAuthService? localAuthService,
  }) : _prefs = prefs,
       _secureStorage = secureStorage,
       _localAuthService = localAuthService;

  /// Инициализация сервиса
  static Future<AppStorageService> init({
    required FlutterSecureStorage secureStorage,
    LocalAuthService? localAuthService,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorageService(
      prefs: prefs,
      secureStorage: secureStorage,
      localAuthService: localAuthService,
    );
  }

  // ==================== Проверка биометрии ====================

  /// Проверяет, включена ли биометрия в настройках
  Future<bool> get isBiometricEnabled async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value?.toLowerCase() == 'true';
  }

  /// Проверяет биометрию для защищённых ключей
  /// Возвращает Success(true) если проверка пройдена или не требуется
  /// Возвращает Failure(StorageError) если проверка не пройдена
  Future<ResultDart<bool, StorageError>> _checkBiometricIfNeeded<T>(
    AppKey<T> key, {
    String reason = 'Подтвердите изменение настройки',
  }) async {
    // Если ключ не требует биометрической защиты - пропускаем
    if (!key.biometricProtect) {
      return const Success(true);
    }

    // Проверяем, включена ли биометрия в настройках
    final biometricEnabled = await isBiometricEnabled;
    if (!biometricEnabled) {
      return const Success(true);
    }

    // Проверяем наличие LocalAuthService
    if (_localAuthService == null) {
      return const Success(true);
    }

    // Проверяем доступность биометрии на устройстве
    final isAvailable = await _localAuthService.isBiometricsAvailable;
    if (!isAvailable) {
      return const Success(true);
    }

    // Запрашиваем биометрическую аутентификацию
    final authResult = await _localAuthService.authenticate(
      localizedReason: reason,
    );

    return authResult.fold(
      (success) => const Success(true),
      (failure) => failure.when(
        canceled: () => const Failure(StorageError.biometricAuthCanceled()),
        notAvailable: () => const Failure(StorageError.biometricNotAvailable()),
        notEnrolled: () =>
            const Success(true), // Биометрия не настроена - пропускаем
        lockedOut: () => const Failure(
          StorageError.biometricAuthFailed(
            message: 'Слишком много попыток. Попробуйте позже.',
          ),
        ),
        permanentlyLockedOut: () => const Failure(
          StorageError.biometricAuthFailed(
            message: 'Биометрия заблокирована. Используйте PIN-код устройства.',
          ),
        ),
        other: (message) =>
            Failure(StorageError.biometricAuthFailed(message: message)),
      ),
    );
  }

  // ==================== Получение значений ====================

  /// Получить значение по типизированному ключу
  Future<T?> get<T>(AppKey<T> key) async {
    if (key.isProtected) {
      return _getSecure<T>(key);
    }
    return _getPrefs<T>(key);
  }

  /// Получить значение или значение по умолчанию
  Future<T> getOrDefault<T>(AppKey<T> key, T defaultValue) async {
    final value = await get(key);
    return value ?? defaultValue;
  }

  /// Получить строку
  Future<String?> getString(AppKey<String> key) async {
    if (key.isProtected) {
      return _secureStorage.read(key: key.key);
    }
    return _prefs.getString(key.key);
  }

  /// Получить целое число
  Future<int?> getInt(AppKey<int> key) async {
    if (key.isProtected) {
      final value = await _secureStorage.read(key: key.key);
      return value != null ? int.tryParse(value) : null;
    }
    return _prefs.getInt(key.key);
  }

  /// Получить число с плавающей точкой
  Future<double?> getDouble(AppKey<double> key) async {
    if (key.isProtected) {
      final value = await _secureStorage.read(key: key.key);
      return value != null ? double.tryParse(value) : null;
    }
    return _prefs.getDouble(key.key);
  }

  /// Получить булево значение
  Future<bool?> getBool(AppKey<bool> key) async {
    if (key.isProtected) {
      final value = await _secureStorage.read(key: key.key);
      return value != null ? value.toLowerCase() == 'true' : null;
    }
    return _prefs.getBool(key.key);
  }

  /// Получить список строк (только SharedPreferences)
  Future<List<String>?> getStringList(AppKey<List<String>> key) async {
    if (key.isProtected) {
      final jsonString = await _secureStorage.read(key: key.key);
      if (jsonString == null) return null;
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<String>();
      } catch (e) {
        return null;
      }
    }
    return _prefs.getStringList(key.key);
  }

  /// Получить JSON объект
  Future<Map<String, dynamic>?> getJson(
    AppKey<Map<String, dynamic>> key,
  ) async {
    final String? jsonString;
    if (key.isProtected) {
      jsonString = await _secureStorage.read(key: key.key);
    } else {
      jsonString = _prefs.getString(key.key);
    }
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== Установка значений ====================

  /// Установить значение по типизированному ключу
  /// Если ключ защищён биометрией и она включена, требуется подтверждение
  AsyncResultDart<bool, StorageError> setWithBiometric<T>(
    AppKey<T> key,
    T value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    // Проверяем биометрию если требуется
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    // Сохраняем значение
    if (key.isProtected) {
      await _setSecure<T>(key, value);
    } else {
      await _setPrefs<T>(key, value);
    }
    return const Success(true);
  }

  /// Установить значение по типизированному ключу (без проверки биометрии)
  Future<bool> set<T>(AppKey<T> key, T value) async {
    if (key.isProtected) {
      await _setSecure<T>(key, value);
      return true;
    }
    return _setPrefs<T>(key, value);
  }

  /// Установить строку с проверкой биометрии
  AsyncResultDart<bool, StorageError> setStringWithBiometric(
    AppKey<String> key,
    String value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value);
    } else {
      await _prefs.setString(key.key, value);
    }
    return const Success(true);
  }

  /// Установить строку (без проверки биометрии)
  Future<bool> setString(AppKey<String> key, String value) async {
    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value);
      return true;
    }
    return _prefs.setString(key.key, value);
  }

  /// Установить целое число с проверкой биометрии
  AsyncResultDart<bool, StorageError> setIntWithBiometric(
    AppKey<int> key,
    int value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value.toString());
    } else {
      await _prefs.setInt(key.key, value);
    }
    return const Success(true);
  }

  /// Установить целое число (без проверки биометрии)
  Future<bool> setInt(AppKey<int> key, int value) async {
    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value.toString());
      return true;
    }
    return _prefs.setInt(key.key, value);
  }

  /// Установить число с плавающей точкой с проверкой биометрии
  AsyncResultDart<bool, StorageError> setDoubleWithBiometric(
    AppKey<double> key,
    double value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value.toString());
    } else {
      await _prefs.setDouble(key.key, value);
    }
    return const Success(true);
  }

  /// Установить число с плавающей точкой (без проверки биометрии)
  Future<bool> setDouble(AppKey<double> key, double value) async {
    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value.toString());
      return true;
    }
    return _prefs.setDouble(key.key, value);
  }

  /// Установить булево значение с проверкой биометрии
  AsyncResultDart<bool, StorageError> setBoolWithBiometric(
    AppKey<bool> key,
    bool value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value.toString());
    } else {
      await _prefs.setBool(key.key, value);
    }
    return const Success(true);
  }

  /// Установить булево значение (без проверки биометрии)
  Future<bool> setBool(AppKey<bool> key, bool value) async {
    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: value.toString());
      return true;
    }
    return _prefs.setBool(key.key, value);
  }

  /// Установить список строк с проверкой биометрии
  AsyncResultDart<bool, StorageError> setStringListWithBiometric(
    AppKey<List<String>> key,
    List<String> value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    if (key.isProtected) {
      final jsonString = jsonEncode(value);
      await _secureStorage.write(key: key.key, value: jsonString);
    } else {
      await _prefs.setStringList(key.key, value);
    }
    return const Success(true);
  }

  /// Установить список строк (без проверки биометрии)
  Future<bool> setStringList(
    AppKey<List<String>> key,
    List<String> value,
  ) async {
    if (key.isProtected) {
      final jsonString = jsonEncode(value);
      await _secureStorage.write(key: key.key, value: jsonString);
      return true;
    }
    return _prefs.setStringList(key.key, value);
  }

  /// Установить JSON объект с проверкой биометрии
  AsyncResultDart<bool, StorageError> setJsonWithBiometric(
    AppKey<Map<String, dynamic>> key,
    Map<String, dynamic> value, {
    String biometricReason = 'Подтвердите изменение настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    final jsonString = jsonEncode(value);
    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: jsonString);
    } else {
      await _prefs.setString(key.key, jsonString);
    }
    return const Success(true);
  }

  /// Установить JSON объект (без проверки биометрии)
  Future<bool> setJson(
    AppKey<Map<String, dynamic>> key,
    Map<String, dynamic> value,
  ) async {
    final jsonString = jsonEncode(value);
    if (key.isProtected) {
      await _secureStorage.write(key: key.key, value: jsonString);
      return true;
    }
    return _prefs.setString(key.key, jsonString);
  }

  // ==================== Удаление и проверка ====================

  /// Удалить значение по ключу с проверкой биометрии
  AsyncResultDart<bool, StorageError> removeWithBiometric<T>(
    AppKey<T> key, {
    String biometricReason = 'Подтвердите удаление настройки',
  }) async {
    final biometricCheck = await _checkBiometricIfNeeded(
      key,
      reason: biometricReason,
    );
    if (biometricCheck.isError()) {
      return Failure(biometricCheck.exceptionOrNull()!);
    }

    if (key.isProtected) {
      await _secureStorage.delete(key: key.key);
    } else {
      await _prefs.remove(key.key);
    }
    return const Success(true);
  }

  /// Удалить значение по ключу (без проверки биометрии)
  Future<bool> remove<T>(AppKey<T> key) async {
    if (key.isProtected) {
      await _secureStorage.delete(key: key.key);
      return true;
    }
    return _prefs.remove(key.key);
  }

  /// Проверить наличие ключа
  Future<bool> containsKey<T>(AppKey<T> key) async {
    if (key.isProtected) {
      return _secureStorage.containsKey(key: key.key);
    }
    return _prefs.containsKey(key.key);
  }

  /// Очистить все настройки в SharedPreferences
  Future<bool> clearPrefs() => _prefs.clear();

  /// Очистить все значения в SecureStorage
  Future<void> clearSecure() => _secureStorage.deleteAll();

  /// Очистить все настройки (оба хранилища)
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }

  /// Получить все ключи SharedPreferences
  Set<String> getPrefsKeys() => _prefs.getKeys();

  /// Получить все ключи SecureStorage
  Future<Map<String, String>> getSecureKeys() => _secureStorage.readAll();

  /// Перезагрузить настройки из SharedPreferences
  Future<void> reloadPrefs() => _prefs.reload();

  // ==================== Утилиты для UI ====================

  /// Получить все ключи по категории (для UI настроек)
  List<AppKey> getKeysByCategory(PrefCategory category, List<AppKey> allKeys) {
    return allKeys
        .where((key) => key.category == category && !key.isHiddenUI)
        .toList();
  }

  /// Получить все редактируемые ключи (для UI настроек)
  List<AppKey> getEditableKeys(List<AppKey> allKeys) {
    return allKeys.where((key) => key.editable && !key.isHiddenUI).toList();
  }

  /// Получить все видимые ключи (для UI настроек)
  List<AppKey> getVisibleKeys(List<AppKey> allKeys) {
    return allKeys.where((key) => !key.isHiddenUI).toList();
  }

  /// Получить все защищённые ключи
  List<AppKey> getProtectedKeys(List<AppKey> allKeys) {
    return allKeys.where((key) => key.isProtected).toList();
  }

  /// Получить все обычные ключи (не защищённые)
  List<AppKey> getUnprotectedKeys(List<AppKey> allKeys) {
    return allKeys.where((key) => !key.isProtected).toList();
  }

  // ==================== Приватные методы ====================

  Future<T?> _getPrefs<T>(AppKey<T> key) async {
    // Для dynamic типа возвращаем null
    if (T == dynamic) {
      return null;
    }

    if (T == String) {
      return _prefs.getString(key.key) as T?;
    } else if (T == int) {
      return _prefs.getInt(key.key) as T?;
    } else if (T == double) {
      return _prefs.getDouble(key.key) as T?;
    } else if (T == bool) {
      return _prefs.getBool(key.key) as T?;
    } else if (T == List<String>) {
      return _prefs.getStringList(key.key) as T?;
    }
    throw UnsupportedError('Type $T is not supported');
  }

  Future<T?> _getSecure<T>(AppKey<T> key) async {
    // Для dynamic типа возвращаем null
    if (T == dynamic) {
      return null;
    }

    final value = await _secureStorage.read(key: key.key);
    if (value == null) return null;

    if (T == String) {
      return value as T;
    } else if (T == int) {
      return int.tryParse(value) as T?;
    } else if (T == double) {
      return double.tryParse(value) as T?;
    } else if (T == bool) {
      return (value.toLowerCase() == 'true') as T;
    }
    throw UnsupportedError('Type $T is not supported for secure storage');
  }

  Future<bool> _setPrefs<T>(AppKey<T> key, T value) async {
    // Для dynamic типа пытаемся определить тип значения
    if (T == dynamic) {
      if (value is String) {
        return _prefs.setString(key.key, value);
      } else if (value is int) {
        return _prefs.setInt(key.key, value);
      } else if (value is double) {
        return _prefs.setDouble(key.key, value);
      } else if (value is bool) {
        return _prefs.setBool(key.key, value);
      } else if (value is List<String>) {
        return _prefs.setStringList(key.key, value);
      }
      throw UnsupportedError(
        'Value type ${value.runtimeType} is not supported',
      );
    }

    if (T == String) {
      return _prefs.setString(key.key, value as String);
    } else if (T == int) {
      return _prefs.setInt(key.key, value as int);
    } else if (T == double) {
      return _prefs.setDouble(key.key, value as double);
    } else if (T == bool) {
      return _prefs.setBool(key.key, value as bool);
    } else if (T == List<String>) {
      return _prefs.setStringList(key.key, value as List<String>);
    }
    throw UnsupportedError('Type $T is not supported');
  }

  Future<void> _setSecure<T>(AppKey<T> key, T value) async {
    String stringValue;
    if (value is String) {
      stringValue = value;
    } else if (value is int || value is double || value is bool) {
      stringValue = value.toString();
    } else {
      throw UnsupportedError(
        'Value type ${value.runtimeType} is not supported for secure storage',
      );
    }
    await _secureStorage.write(key: key.key, value: stringValue);
  }
}
