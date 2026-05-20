class StoreOpenCompatibility {
  const StoreOpenCompatibility({
    required this.currentManifestVersion,
    required this.currentSchemaVersion,
    required this.currentAppVersion,
    this.storeManifestVersion,
    this.storeSchemaVersion,
    this.storeAppVersion,
    this.requiresMigration = false,
    this.manifestVersionTooNew = false,
    this.schemaVersionTooNew = false,
    this.appVersionTooNew = false,
  });

  final int currentManifestVersion;
  final int? storeManifestVersion;
  final int currentSchemaVersion;
  final int? storeSchemaVersion;
  final String currentAppVersion;
  final String? storeAppVersion;
  final bool requiresMigration;
  final bool manifestVersionTooNew;
  final bool schemaVersionTooNew;
  final bool appVersionTooNew;

  bool get blocksOpen =>
      manifestVersionTooNew || schemaVersionTooNew || appVersionTooNew;

  Map<String, dynamic> toErrorData(String storagePath) {
    return <String, dynamic>{
      'path': storagePath,
      'currentManifestVersion': currentManifestVersion,
      'storeManifestVersion': storeManifestVersion,
      'currentSchemaVersion': currentSchemaVersion,
      'storeSchemaVersion': storeSchemaVersion,
      'currentAppVersion': currentAppVersion,
      'storeAppVersion': storeAppVersion,
      'requiresMigration': requiresMigration,
      'manifestVersionTooNew': manifestVersionTooNew,
      'schemaVersionTooNew': schemaVersionTooNew,
      'appVersionTooNew': appVersionTooNew,
    };
  }
}
