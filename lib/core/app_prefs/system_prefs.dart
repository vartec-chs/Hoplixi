import "package:typed_prefs/typed_prefs.dart";

part 'system_prefs.g.dart';

@Prefs()
class SystemPrefs {
  @Pref(defaultValue: true)
  static const isFirstLaunch = PrefKey<bool>();

  @Pref(defaultValue: false)
  static const setupCompleted = PrefKey<bool>();

  static const lastSyncTime = PrefKey<int>();
}
