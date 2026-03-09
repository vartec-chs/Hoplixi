import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/auth_prefs.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/app_prefs/system_prefs.dart';
import 'package:hoplixi/core/localization/locale_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';

class SettingsNotifier extends Notifier<Map<String, dynamic>> {
  late final PreferencesService _service;

  SettingsPrefsStore get _settings => _service.settingsPrefs;
  SystemPrefsStore get _system => _service.systemPrefs;
  AuthPrefsStore get _auth => _service.authPrefs;

  @override
  Map<String, dynamic> build() {
    _service = getIt<PreferencesService>();
    _loadSettings();
    return {};
  }

  Future<void> _loadSettings() async {
    try {
      final raw = <String, dynamic>{
        'theme_mode': await _settings.getThemeMode(),
        'language': await _settings.getLanguage(),
        'launch_at_startup_enabled': await _settings.getLaunchAtStartupEnabled(),
        'auto_lock_timeout': await _settings.getAutoLockTimeout(),
        'auto_sync_enabled': await _settings.getAutoSyncEnabled(),
        'auto_backup_enabled': await _settings.getAutoBackupEnabled(),
        'backup_path': await _settings.getBackupPath(),
        'backup_scope': await _settings.getBackupScope(),
        'backup_interval_minutes': await _settings.getBackupIntervalMinutes(),
        'backup_max_per_store': await _settings.getBackupMaxPerStore(),
        'is_first_launch': await _system.getIsFirstLaunch(),
        'setup_completed': await _system.getSetupCompleted(),
        'last_sync_time': await _system.getLastSyncTime(),
        'biometric_enabled': await _auth.getBiometricEnabled(),
        'pin_attempts': await _auth.getPinAttempts(),
      };
      raw.removeWhere((_, v) => v == null);
      state = raw;
    } catch (e, s) {
      logError('Error loading settings', error: e, stackTrace: s);
    }
  }

  T? getSetting<T>(String key) => state[key] as T?;

  Future<void> setString(String key, String value) async {
    switch (key) {
      case 'language':
        await _settings.setLanguage(value);
        await ref.read(localeProvider.notifier).setLocaleCode(value, persist: false);
      case 'backup_path':
        await _settings.setBackupPath(value);
      case 'backup_scope':
        await _settings.setBackupScope(value);
      default:
        logError('Unknown string key: $key');
        return;
    }
    state = {...state, key: value};
  }

  Future<void> setBool(String key, bool value) async {
    switch (key) {
      case 'launch_at_startup_enabled':
        await _settings.setLaunchAtStartupEnabled(value);
      case 'auto_sync_enabled':
        await _settings.setAutoSyncEnabled(value);
      case 'auto_backup_enabled':
        await _settings.setAutoBackupEnabled(value);
      case 'is_first_launch':
        await _system.setIsFirstLaunch(value);
      case 'setup_completed':
        await _system.setSetupCompleted(value);
      case 'biometric_enabled':
        await _auth.setBiometricEnabled(value);
      default:
        logError('Unknown bool key: $key');
        return;
    }
    state = {...state, key: value};
  }

  Future<void> setInt(String key, int value) async {
    switch (key) {
      case 'auto_lock_timeout':
        await _settings.setAutoLockTimeout(value);
      case 'backup_interval_minutes':
        await _settings.setBackupIntervalMinutes(value);
      case 'backup_max_per_store':
        await _settings.setBackupMaxPerStore(value);
      case 'last_sync_time':
        await _system.setLastSyncTime(value);
      case 'pin_attempts':
        await _auth.setPinAttempts(value);
      default:
        logError('Unknown int key: $key');
        return;
    }
    state = {...state, key: value};
  }

  Future<void> reload() async => _loadSettings();
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, dynamic>>(
      SettingsNotifier.new,
    );

