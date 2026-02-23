import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_key.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/core/app_preferences/app_storage_service.dart';
import 'package:hoplixi/core/app_preferences/storage_errors.dart';
import 'package:hoplixi/core/localization/locale_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/di_init.dart';

/// Провайдер для работы с настройками
class SettingsNotifier extends Notifier<Map<String, dynamic>> {
  late final AppStorageService _storage;

  @override
  Map<String, dynamic> build() {
    _storage = getIt<AppStorageService>();
    _loadSettings();
    return {};
  }

  /// Загрузить все настройки
  Future<void> _loadSettings() async {
    final settings = <String, dynamic>{};

    // Загружаем все ключи
    for (final key in AppKeys.getAllKeys()) {
      try {
        dynamic value;

        // Используем специализированные методы на основе проверки runtimeType
        final typeString = key.runtimeType.toString();
        if (typeString.contains('AppKey<String>')) {
          value = await _storage.getString(key as AppKey<String>);
        } else if (typeString.contains('AppKey<int>')) {
          value = await _storage.getInt(key as AppKey<int>);
        } else if (typeString.contains('AppKey<bool>')) {
          value = await _storage.getBool(key as AppKey<bool>);
        } else if (typeString.contains('AppKey<double>')) {
          value = await _storage.getDouble(key as AppKey<double>);
        } else if (typeString.contains('List<String>')) {
          value = await _storage.getStringList(key as AppKey<List<String>>);
        } else {
          // Для неизвестных типов пропускаем
          logError('Unknown key type: $typeString for key ${key.key}');
          continue;
        }

        if (value != null) {
          settings[key.key] = value;
        }
      } catch (e, s) {
        logError('Error loading setting ${key.key}', error: e, stackTrace: s);
      }
    }

    state = settings;
  }

  /// Получить значение настройки
  T? getSetting<T>(String key) {
    return state[key] as T?;
  }

  /// Установить строковое значение
  Future<void> setString(String key, String value) async {
    final appKey = AppKeys.getAllKeys().firstWhere((k) => k.key == key);
    final result = await _storage.setString(appKey as AppKey<String>, value);
    if (result) {
      state = {...state, key: value};

      if (key == AppKeys.language.key) {
        await ref
            .read(localeProvider.notifier)
            .setLocaleCode(value, persist: false);
      }
    }
  }

  /// Установить булево значение (без биометрии)
  Future<void> setBool(String key, bool value) async {
    final appKey = AppKeys.getAllKeys().firstWhere((k) => k.key == key);
    final result = await _storage.setBool(appKey as AppKey<bool>, value);
    if (result) {
      state = {...state, key: value};
    }
  }

  /// Установить целочисленное значение
  Future<void> setInt(String key, int value) async {
    final appKey = AppKeys.getAllKeys().firstWhere((k) => k.key == key);
    final result = await _storage.setInt(appKey as AppKey<int>, value);
    if (result) {
      state = {...state, key: value};
    }
  }

  /// Установить булево значение с биометрией
  Future<void> setBoolWithBiometric(
    String key,
    bool value, {
    String? reason,
  }) async {
    final appKey = AppKeys.getAllKeys().firstWhere((k) => k.key == key);
    final result = await _storage.setBoolWithBiometric(
      appKey as AppKey<bool>,
      value,
      biometricReason: reason ?? 'Подтвердите изменение настройки',
    );

    result.fold(
      (success) {
        state = {...state, key: value};
        Toaster.success(
          title: 'Настройка обновлена',
          description: 'Изменения сохранены',
        );
      },
      (error) {
        error.when(
          biometricAuthFailed: (message) {
            Toaster.error(title: 'Ошибка аутентификации', description: message);
          },
          biometricAuthCanceled: () {
            Toaster.info(
              title: 'Отменено',
              description: 'Аутентификация отменена пользователем',
            );
          },
          biometricNotAvailable: () {
            Toaster.warning(
              title: 'Биометрия недоступна',
              description:
                  'На устройстве не настроена биометрическая аутентификация',
            );
          },
          unsupportedType: (typeName) {
            Toaster.error(
              title: 'Ошибка',
              description: 'Неподдерживаемый тип данных: $typeName',
            );
          },
        );
      },
    );
  }

  /// Установить строковое значение с биометрией
  Future<void> setStringWithBiometric(
    String key,
    String value, {
    String? reason,
  }) async {
    final appKey = AppKeys.getAllKeys().firstWhere((k) => k.key == key);
    final result = await _storage.setStringWithBiometric(
      appKey as AppKey<String>,
      value,
      biometricReason: reason ?? 'Подтвердите изменение настройки',
    );

    result.fold(
      (success) {
        state = {...state, key: value};
        Toaster.success(
          title: 'Настройка обновлена',
          description: 'Изменения сохранены',
        );
      },
      (error) {
        error.when(
          biometricAuthFailed: (message) {
            Toaster.error(title: 'Ошибка аутентификации', description: message);
          },
          biometricAuthCanceled: () {
            Toaster.info(
              title: 'Отменено',
              description: 'Аутентификация отменена пользователем',
            );
          },
          biometricNotAvailable: () {
            Toaster.warning(
              title: 'Биометрия недоступна',
              description:
                  'На устройстве не настроена биометрическая аутентификация',
            );
          },
          unsupportedType: (typeName) {
            Toaster.error(
              title: 'Ошибка',
              description: 'Неподдерживаемый тип данных: $typeName',
            );
          },
        );
      },
    );
  }

  /// Перезагрузить настройки
  Future<void> reload() async {
    await _loadSettings();
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, dynamic>>(
      SettingsNotifier.new,
    );
