import "package:typed_prefs/typed_prefs.dart";

part 'auth_prefs.g.dart';

@Prefs(protected: true)
class AuthPrefs {
  @Pref(defaultValue: false)
  static const biometricEnabled = PrefKey<bool>();

  static const pinCode = PrefKey<String>();

  @Pref(defaultValue: 0)
  static const pinAttempts = PrefKey<int>();
}
