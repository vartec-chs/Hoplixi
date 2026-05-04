import 'app_guide_id.dart';

const appGuideVersions = <AppGuideId, int>{
  AppGuideId.home: 2,
  AppGuideId.createStore: 1,
  AppGuideId.dashboard: 1,
  AppGuideId.passwordAdd: 1,
  AppGuideId.cloudSyncPlayground: 1,
};

int currentAppGuideVersion(AppGuideId id) => appGuideVersions[id] ?? 1;
