enum AppGuideId {
  home,
  createStore,
  dashboard,
  passwordAdd,
}

extension AppGuideIdStorageKey on AppGuideId {
  String get storageKey => switch (this) {
    AppGuideId.home => 'home',
    AppGuideId.createStore => 'create_store',
    AppGuideId.dashboard => 'dashboard',
    AppGuideId.passwordAdd => 'password_add',
  };
}

