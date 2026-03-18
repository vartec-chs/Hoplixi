import "package:typed_prefs/typed_prefs.dart";

part 'security_prefs.g.dart';

@Prefs(protected: true, writePolicy: 'biometric')
class SecurityPrefs {
  @Pref(defaultValue: false)
  static const biometricEnabled = PrefKey<bool>();

  static const pinCode = PrefKey<String>();

  // Защита dashboard от записи экрана и скриншотов
  @Pref(defaultValue: true)
  static const preventScreenCaptureOnDashboard = PrefKey<bool>();

  // Дополнение к защите dashboard: blur overlay в app switcher / recents
  @Pref(defaultValue: false)
  static const dashboardScreenBlurOverlayEnabled = PrefKey<bool>();

  @Pref(defaultValue: 0)
  static const pinAttempts = PrefKey<int>();
}
