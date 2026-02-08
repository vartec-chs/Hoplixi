import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_storage_service.dart';
import 'app_preference_keys.dart';
import 'pref_category.dart';

/// Примеры использования AppStorageService (унифицированный сервис хранения)

void exampleUsage() async {
  // ==================== Инициализация ====================

  // Инициализация унифицированного сервиса
  final storage = await AppStorageService.init(
    secureStorage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(),
      mOptions: MacOsOptions(),
      webOptions: WebOptions(),
    ),
  );

  // ==================== Работа с обычными настройками (SharedPreferences) ====================

  // Сохранение значений (автоматически использует SharedPreferences для обычных ключей)
  await storage.set(AppKeys.themeMode, 'dark');
  await storage.setInt(AppKeys.autoLockTimeout, 300);
  await storage.setBool(AppKeys.biometricEnabled, true);
  // await storage.setDouble(AppKeys.fontSize, 14.5);

  // Сохранение JSON
  // await storage.setJson(AppKeys.userSettings, {
  //   'theme': 'dark',
  //   'notifications': true,
  //   'language': 'ru',
  // });

  // Сохранение списка
  // await storage.setStringList(AppKeys.recentSearches, [
  //   'password',
  //   'email',
  //   'login',
  // ]);

  // Чтение значений
  final themeMode = await storage.get(AppKeys.themeMode);
  final timeout = await storage.getInt(AppKeys.autoLockTimeout);
  final biometric = await storage.getBool(AppKeys.biometricEnabled);
  // final fontSize = await storage.getDouble(AppKeys.fontSize);

  // Чтение с значением по умолчанию
  final language = await storage.getOrDefault(AppKeys.language, 'en');

  // Чтение JSON
  // final userSettings = await storage.getJson(AppKeys.userSettings);

  // Проверка наличия ключа
  if (await storage.containsKey(AppKeys.isFirstLaunch)) {
    debugPrint('Приложение уже запускалось');
  } else {
    await storage.setBool(AppKeys.isFirstLaunch, false);
  }

  // Получение всех ключей из SharedPreferences
  final allKeys = storage.getPrefsKeys();
  debugPrint('Всего ключей: ${allKeys.length}');

  // ==================== Работа с защищёнными данными (SecureStorage) ====================
  // Защищённые ключи автоматически используют FlutterSecureStorage

  await storage.setInt(AppKeys.pinAttempts, 0);

  final pinAttempts = await storage.getInt(AppKeys.pinAttempts);

  // Чтение с значением по умолчанию
  final attempts = await storage.getOrDefault(AppKeys.pinAttempts, 0);

  // Получение всех ключей из SecureStorage
  final allSecureData = await storage.getSecureKeys();
  debugPrint('Всего защищенных ключей: ${allSecureData.length}');

  // Очистка всех данных
  // await storage.clearAll(); // Обе хранилища
  // await storage.clearPrefs(); // Только SharedPreferences
  // await storage.clearSecure(); // Только SecureStorage

  // ==================== Работа с UI настройками ====================

  // Получить все видимые настройки
  final visibleKeys = storage.getVisibleKeys(AppKeys.getAllKeys());

  // Получить редактируемые настройки
  final editableKeys = storage.getEditableKeys(AppKeys.getAllKeys());

  // Получить настройки по категории
  final securityKeys = storage.getKeysByCategory(
    PrefCategory.security,
    AppKeys.getAllKeys(),
  );

  // Получить только защищённые ключи
  final protectedKeys = storage.getProtectedKeys(AppKeys.getAllKeys());
  debugPrint('Защищённых ключей: ${protectedKeys.length}');

  // Получить только обычные ключи
  final unprotectedKeys = storage.getUnprotectedKeys(AppKeys.getAllKeys());
  debugPrint('Обычных ключей: ${unprotectedKeys.length}');

  // Пример использования в UI
  for (final key in securityKeys) {
    debugPrint('Настройка безопасности: ${key.key}');
    debugPrint('  Защищённая: ${key.isProtected}');
    debugPrint('  Можно редактировать: ${key.editable}');
    debugPrint('  Скрыта в UI: ${key.isHiddenUI}');
  }

  // Использование переменных для подавления предупреждений
  debugPrint('themeMode: $themeMode');
  debugPrint('timeout: $timeout');
  debugPrint('biometric: $biometric');
  // debugPrint('fontSize: $fontSize');
  debugPrint('language: $language');
  // debugPrint('userSettings: $userSettings');
  debugPrint('pinAttempts: $pinAttempts');
  debugPrint('attempts: $attempts');
  // debugPrint('credentials: $credentials');
  // debugPrint('sessionData: $sessionData');
  debugPrint('visibleKeys: ${visibleKeys.length}');
  debugPrint('editableKeys: ${editableKeys.length}');
}

/// Пример провайдера для Riverpod
class StorageProviderExample {
  // Provider для AppStorageService
  // final appStorageProvider = Provider<AppStorageService>((ref) {
  //   throw UnimplementedError('Должен быть инициализирован в main()');
  // });

  // Пример провайдера для конкретной настройки
  // final themeModeProvider = FutureProvider<String>((ref) async {
  //   final storage = ref.watch(appStorageProvider);
  //   return storage.getOrDefault(AppKeys.themeMode, 'system');
  // });
}
