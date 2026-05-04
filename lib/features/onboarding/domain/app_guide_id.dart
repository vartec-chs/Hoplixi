enum AppGuideId {
  home,
  createStore,
  dashboard,
  passwordAdd,
  cloudSyncPlayground,
}

extension AppGuideIdStorageKey on AppGuideId {
  String get storageKey => switch (this) {
    AppGuideId.home => 'home',
    AppGuideId.createStore => 'create_store',
    AppGuideId.dashboard => 'dashboard',
    AppGuideId.passwordAdd => 'password_add',
    AppGuideId.cloudSyncPlayground => 'cloud_sync_playground',
  };
}
