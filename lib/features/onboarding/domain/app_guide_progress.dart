import 'app_guide_id.dart';

const appGuideVersions = <AppGuideId, int>{
  AppGuideId.home: 1,
  AppGuideId.createStore: 1,
  AppGuideId.dashboard: 1,
  AppGuideId.passwordAdd: 1,
};

int currentAppGuideVersion(AppGuideId id) => appGuideVersions[id] ?? 1;

