import 'package:local_auth/local_auth.dart';
import "package:typed_prefs/typed_prefs.dart";

import 'security_prefs.dart';
import 'settings_prefs.dart';
import 'system_prefs.dart';

part 'app_prefs.g.dart';

@Prefs()
class AppPrefs {
  static const settings = PrefGroupKey<SettingsPrefs>();
  static const system = PrefGroupKey<SystemPrefs>();
  static const auth = PrefGroupKey<SecurityPrefs>();
}

class BiometricAuthPolicy implements PreferenceWritePolicy {
  final LocalAuthentication _auth;
  final String localizedReason;

  const BiometricAuthPolicy(
    this._auth, {
    this.localizedReason = 'Authenticate to change secure settings',
  });

  @override
  Future<void> authorize<T>(PreferenceWriteRequest<T> request) async {
    final authenticated = await _auth.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) {
      throw const PreferenceWriteDeniedException(
        'Biometric authentication failed or was cancelled.',
      );
    }
  }
}


