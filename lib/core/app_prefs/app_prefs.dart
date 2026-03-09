import "package:typed_prefs/typed_prefs.dart";

import 'auth_prefs.dart';
import 'settings_prefs.dart';
import 'system_prefs.dart';

part 'app_prefs.g.dart';

@Prefs()
class AppPrefs {
  static const settings = PrefGroupKey<SettingsPrefs>();
  static const system = PrefGroupKey<SystemPrefs>();
  static const auth = PrefGroupKey<AuthPrefs>();
}
