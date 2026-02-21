import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../app_preferences/app_preference_keys.dart';
import '../app_preferences/app_storage_service.dart';
import '../logger/index.dart';
import 'launch_at_startup_service.dart';

/// Сервис для однократного применения конфигурации установщика.
///
/// При первом запуске после установки Windows-инсталлятор (Inno Setup)
/// создаёт файл `install_config.json` рядом с exe. Этот сервис читает
/// файл, записывает настройки в [AppStorageService], применяет автозапуск
/// через [LaunchAtStartupService], а затем удаляет файл.
///
/// Файл имеет следующий формат:
/// ```json
/// {
///   "lang": "russian",
///   "autorun": 1
/// }
/// ```
class InstallConfigService {
  InstallConfigService._();

  static final _log = loggerWithTag('InstallConfigService');

  /// Проверяет наличие `install_config.json`, применяет настройки и удаляет файл.
  ///
  /// Вызовите один раз при запуске приложения после инициализации DI.
  /// Безопасно вызывать повторно: если файл отсутствует — ничего не происходит.
  static Future<void> applyIfPresent({
    required AppStorageService storage,
    required LaunchAtStartupService launchAtStartupService,
  }) async {
    if (!Platform.isWindows) {
      return;
    }

    final configFile = _resolveConfigFile();
    if (!await configFile.exists()) {
      return;
    }

    _log.info('Найден install_config.json — применяем настройки установщика');

    try {
      final json = await _readJson(configFile);
      if (json == null) {
        await _safeDelete(configFile);
        return;
      }

      await _applyLanguage(json, storage);
      await _applyAutorun(json, storage, launchAtStartupService);

      await _safeDelete(configFile);
      _log.info('install_config.json успешно обработан и удалён');
    } catch (error, stackTrace) {
      _log.error(
        'Ошибка при обработке install_config.json',
        error: error,
        stackTrace: stackTrace,
      );
      // Удаляем файл даже при ошибке, чтобы не повторять при следующем запуске
      await _safeDelete(configFile);
    }
  }

  // ---------------------------------------------------------------------------
  // Приватные методы
  // ---------------------------------------------------------------------------

  static File _resolveConfigFile() {
    final exeDir = path.dirname(Platform.resolvedExecutable);
    return File(path.join(exeDir, 'install_config.json'));
  }

  static Future<Map<String, dynamic>?> _readJson(File file) async {
    try {
      final text = await file.readAsString();
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      _log.warning('install_config.json содержит неверный формат');
      return null;
    } catch (error, stackTrace) {
      _log.error(
        'Не удалось прочитать install_config.json',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Применяет язык из конфига, если ключ ещё не задан.
  static Future<void> _applyLanguage(
    Map<String, dynamic> json,
    AppStorageService storage,
  ) async {
    final rawLang = json['lang'];
    if (rawLang is! String || rawLang.isEmpty) {
      return;
    }

    // Уже задан пользователем — не перезаписываем
    final existing = await storage.getString(AppKeys.language);
    if (existing != null) {
      return;
    }

    // Inno Setup возвращает полное имя языка ('russian', 'english' и т.д.).
    // Приводим к двухбуквенному коду ISO 639-1.
    final langCode = _normalizeLanguageCode(rawLang);
    await storage.setString(AppKeys.language, langCode);
    _log.info('Язык установлен из install_config.json: $langCode');
  }

  /// Применяет настройку автозапуска из конфига, если ключ ещё не задан.
  static Future<void> _applyAutorun(
    Map<String, dynamic> json,
    AppStorageService storage,
    LaunchAtStartupService launchAtStartupService,
  ) async {
    final rawAutorun = json['autorun'];
    // Inno Setup пишет целое число: 1 = включить, 0 = выключить
    final bool autorunEnabled;
    if (rawAutorun is int) {
      autorunEnabled = rawAutorun == 1;
    } else if (rawAutorun is bool) {
      autorunEnabled = rawAutorun;
    } else {
      return;
    }

    // Уже задан пользователем — не перезаписываем
    final existing = await storage.getBool(AppKeys.launchAtStartupEnabled);
    if (existing != null) {
      return;
    }

    await storage.setBool(AppKeys.launchAtStartupEnabled, autorunEnabled);

    if (autorunEnabled) {
      await launchAtStartupService.setEnabled(true);
      _log.info('Автозапуск включён на основании выбора в установщике');
    }
  }

  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      _log.warning('Не удалось удалить install_config.json: $error');
    }
  }

  /// Преобразует имя языка Inno Setup в ISO 639-1 код.
  ///
  /// Inno Setup передаёт значение `ActiveLanguage()` — это Name из `[Languages]`
  /// (например `russian`, `english`, `german`).
  static String _normalizeLanguageCode(String innoLang) {
    const map = <String, String>{
      'russian': 'ru',
      'english': 'en',
      'german': 'de',
      'french': 'fr',
      'spanish': 'es',
      'italian': 'it',
      'portuguese': 'pt',
      'polish': 'pl',
      'ukrainian': 'uk',
      'belarusian': 'be',
      'czech': 'cs',
      'slovak': 'sk',
      'dutch': 'nl',
      'turkish': 'tr',
      'chinese': 'zh',
      'japanese': 'ja',
      'korean': 'ko',
      'arabic': 'ar',
    };
    return map[innoLang.toLowerCase()] ?? innoLang.toLowerCase();
  }
}
