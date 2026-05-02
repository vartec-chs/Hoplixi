import 'package:hoplixi/features/onboarding/domain/app_guide_id.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ShowcaseStorage {
  Future<int?> getSeenVersion(AppGuideId id);
  Future<void> markSeen(AppGuideId id, int version);
  Future<void> resetGuide(AppGuideId id);
  Future<void> resetAllGuides();
}

class SharedPreferencesShowcaseStorage implements ShowcaseStorage {
  SharedPreferencesShowcaseStorage(this._prefs);

  final SharedPreferences _prefs;

  static String keyFor(AppGuideId id) =>
      'showcase.${id.storageKey}.seenVersion';

  @override
  Future<int?> getSeenVersion(AppGuideId id) async {
    return _prefs.getInt(keyFor(id));
  }

  @override
  Future<void> markSeen(AppGuideId id, int version) async {
    await _prefs.setInt(keyFor(id), version);
  }

  @override
  Future<void> resetGuide(AppGuideId id) async {
    await _prefs.remove(keyFor(id));
  }

  @override
  Future<void> resetAllGuides() async {
    for (final id in AppGuideId.values) {
      await resetGuide(id);
    }
  }
}

ShowcaseStorage createShowcaseStorage() {
  return SharedPreferencesShowcaseStorage(getIt<SharedPreferences>());
}

