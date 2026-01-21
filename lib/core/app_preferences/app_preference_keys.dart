import 'app_key.dart';
import 'pref_category.dart';

/// Типизированные ключи настроек приложения
///
/// Все ключи используют унифицированный класс [AppKey].
/// Флаг `isProtected: true` означает хранение в FlutterSecureStorage.
class AppKeys {
  AppKeys._();

  static const String biometricEnabledConst = 'biometric_enabled';

  // ==================== Общие настройки ====================

  static const themeMode = AppKey<String>(
    'theme_mode',
    category: PrefCategory.appearance,
    editable: true,
    isHiddenUI: false,
  );

  static const language = AppKey<String>(
    'language',
    category: PrefCategory.general,
    editable: true,
    isHiddenUI: false,
  );

  static const isFirstLaunch = AppKey<bool>(
    'is_first_launch',
    category: PrefCategory.system,
    editable: false,
    isHiddenUI: true,
  );

  static const setupCompleted = AppKey<bool>(
    'setup_completed',
    category: PrefCategory.system,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== Настройки безопасности ====================

  static const autoLockTimeout = AppKey<int>(
    'auto_lock_timeout',
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
  );

  // ==================== Настройки синхронизации ====================

  static const autoSyncEnabled = AppKey<bool>(
    'auto_sync_enabled',
    category: PrefCategory.sync,
    editable: true,
    isHiddenUI: false,
  );

  static const lastSyncTime = AppKey<int>(
    'last_sync_time',
    category: PrefCategory.sync,
    editable: false,
    isHiddenUI: true,
  );

  // ==================== Настройки резервного копирования ====================

  static const autoBackupEnabled = AppKey<bool>(
    'auto_backup_enabled',
    category: PrefCategory.backup,
    editable: true,
    isHiddenUI: false,
  );

  static const backupPath = AppKey<String>(
    'backup_path',
    category: PrefCategory.backup,
    editable: true,
    isHiddenUI: false,
  );

  // ==================== Защищённые ключи (SecureStorage) ====================

  /// Включена ли биометрия (требует подтверждения биометрией при изменении)
  static const biometricEnabled = AppKey<bool>(
    biometricEnabledConst,
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
    isProtected: true,
    biometricProtect: true,
  );

  /// PIN код (защищённое хранилище, требует подтверждения биометрией)
  static const pinCode = AppKey<String>(
    'pin_code',
    isProtected: true,
    biometricProtect: true,
    category: PrefCategory.security,
    editable: true,
    isHiddenUI: false,
  );

  /// Количество попыток ввода PIN (защищённое хранилище)
  static const pinAttempts = AppKey<int>(
    'pin_attempts',
    isProtected: true,
    category: PrefCategory.security,
    editable: false,
    isHiddenUI: true,
  );

  /// Получить все ключи
  static List<AppKey> getAllKeys() {
    return [
      // Обычные настройки
      themeMode,
      language,
      isFirstLaunch,
      setupCompleted,
      autoLockTimeout,
      biometricEnabled,

      autoSyncEnabled,
      lastSyncTime,
      autoBackupEnabled,
      backupPath,
      pinCode,
      pinAttempts,
    ];
  }

  /// Получить только обычные ключи (SharedPreferences)
  static List<AppKey> getUnprotectedKeys() {
    return getAllKeys().where((key) => !key.isProtected).toList();
  }

  /// Получить только защищённые ключи (SecureStorage)
  static List<AppKey> getProtectedKeys() {
    return getAllKeys().where((key) => key.isProtected).toList();
  }
}

// ==================== Устаревшие классы для обратной совместимости ====================

/// @Deprecated Используйте [AppKeys] вместо этого класса
@Deprecated('Используйте AppKeys вместо AppPreferenceKeys')
typedef AppPreferenceKeys = AppKeys;

/// @Deprecated Используйте [AppKeys] вместо этого класса
@Deprecated('Используйте AppKeys вместо AppSecureKeys')
typedef AppSecureKeys = AppKeys;
