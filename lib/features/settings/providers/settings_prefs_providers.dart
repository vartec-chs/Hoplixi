import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/security_prefs.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/app_prefs/system_prefs.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';

final launchAtStartupEnabledProvider = StreamProvider<bool>(
  (ref) =>
      getIt<PreferencesService>().settingsPrefs.watchLaunchAtStartupEnabled(),
);

final autoLockTimeoutProvider = StreamProvider<int>(
  (ref) => getIt<PreferencesService>().settingsPrefs.watchAutoLockTimeout(),
);

final biometricEnabledProvider = StreamProvider<bool>(
  (ref) => getIt<PreferencesService>().securityPrefs.watchBiometricEnabled(),
);

final preventScreenCaptureOnDashboardProvider = StreamProvider<bool>(
  (ref) => getIt<PreferencesService>().securityPrefs
      .watchPreventScreenCaptureOnDashboard(),
);

final dashboardScreenBlurOverlayEnabledProvider = StreamProvider<bool>(
  (ref) => getIt<PreferencesService>().securityPrefs
      .watchDashboardScreenBlurOverlayEnabled(),
);

final autoSyncEnabledProvider = StreamProvider<bool>(
  (ref) => getIt<PreferencesService>().settingsPrefs.watchAutoSyncEnabled(),
);

final autoUploadSnapshotOnCloseEnabledProvider = StreamProvider<bool>(
  (ref) => getIt<PreferencesService>().settingsPrefs
      .watchAutoUploadSnapshotOnCloseEnabled(),
);

final lastSyncTimeProvider = StreamProvider<int?>(
  (ref) => getIt<PreferencesService>().systemPrefs.watchLastSyncTime(),
);

final autoBackupEnabledProvider = StreamProvider<bool>(
  (ref) => getIt<PreferencesService>().settingsPrefs.watchAutoBackupEnabled(),
);

final backupPathProvider = StreamProvider<String?>(
  (ref) => getIt<PreferencesService>().settingsPrefs.watchBackupPath(),
);

final backupScopeProvider = StreamProvider<String?>(
  (ref) => getIt<PreferencesService>().settingsPrefs.watchBackupScope(),
);

final backupIntervalMinutesProvider = StreamProvider<int>(
  (ref) =>
      getIt<PreferencesService>().settingsPrefs.watchBackupIntervalMinutes(),
);

final backupMaxPerStoreProvider = StreamProvider<int>(
  (ref) => getIt<PreferencesService>().settingsPrefs.watchBackupMaxPerStore(),
);
