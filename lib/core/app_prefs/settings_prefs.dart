import 'package:flutter/material.dart';
import "package:typed_prefs/typed_prefs.dart";

part 'settings_prefs.g.dart';

@Prefs()
class SettingsPrefs {
  @Pref(defaultValue: ThemeMode.system, serializer: EnumPrefSerializer)
  static const themeMode = PrefKey<ThemeMode>();

  static const language = PrefKey<String>();

  @Pref(defaultValue: false)
  static const launchAtStartupEnabled = PrefKey<bool>();

  @Pref(defaultValue: 0)
  static const autoLockTimeout = PrefKey<int>();

  @Pref(defaultValue: false)
  static const autoSyncEnabled = PrefKey<bool>();

  @Pref(defaultValue: false)
  static const autoUploadSnapshotOnCloseEnabled = PrefKey<bool>();

  @Pref(defaultValue: true)
  static const dashboardAnimationsEnabled = PrefKey<bool>();

  @Pref(defaultValue: true)
  static const dashboardFloatingNavEffectsEnabled = PrefKey<bool>();

  @Pref(defaultValue: 15)
  static const dashboardAnimatedItemsThreshold = PrefKey<int>();

  @Pref(defaultValue: false)
  static const autoBackupEnabled = PrefKey<bool>();

  static const backupPath = PrefKey<String>();

  static const backupScope = PrefKey<String>();

  @Pref(defaultValue: 60)
  static const backupIntervalMinutes = PrefKey<int>();

  @Pref(defaultValue: 10)
  static const backupMaxPerStore = PrefKey<int>();
}
