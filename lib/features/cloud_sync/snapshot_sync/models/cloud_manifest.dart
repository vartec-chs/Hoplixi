class CloudManifestStoreEntry {
  const CloudManifestStoreEntry({
    required this.storeUuid,
    required this.storeName,
    required this.revision,
    required this.updatedAt,
    required this.snapshotId,
    this.remoteStoreId,
    this.remotePath,
    this.manifestSha256,
    this.deleted = false,
  });

  final String storeUuid;
  final String storeName;
  final int revision;
  final DateTime updatedAt;
  final String snapshotId;
  final String? remoteStoreId;
  final String? remotePath;
  final String? manifestSha256;
  final bool deleted;

  factory CloudManifestStoreEntry.fromJson(Map<String, dynamic> json) {
    return CloudManifestStoreEntry(
      storeUuid: (json['storeUuid'] as String?)?.trim() ?? '',
      storeName: (json['storeName'] as String?)?.trim() ?? '',
      revision: _toInt(json['revision']),
      updatedAt:
          _tryParseDateTime(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      snapshotId: (json['snapshotId'] as String?)?.trim() ?? '',
      remoteStoreId: (json['remoteStoreId'] as String?)?.trim(),
      remotePath: (json['remotePath'] as String?)?.trim(),
      manifestSha256: (json['manifestSha256'] as String?)?.trim(),
      deleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'storeUuid': storeUuid,
      'storeName': storeName,
      'revision': revision,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'snapshotId': snapshotId,
      'remoteStoreId': remoteStoreId,
      'remotePath': remotePath,
      'manifestSha256': manifestSha256,
      'deleted': deleted,
    };
  }
}

class CloudManifest {
  const CloudManifest({
    required this.version,
    required this.updatedAt,
    required this.stores,
  });

  final int version;
  final DateTime updatedAt;
  final List<CloudManifestStoreEntry> stores;

  factory CloudManifest.empty() {
    return CloudManifest(
      version: 1,
      updatedAt: DateTime.now().toUtc(),
      stores: const <CloudManifestStoreEntry>[],
    );
  }

  factory CloudManifest.fromJson(Map<String, dynamic> json) {
    final rawStores = json['stores'];
    return CloudManifest(
      version: _toInt(json['version'], fallback: 1),
      updatedAt: _tryParseDateTime(json['updatedAt']) ?? DateTime.now().toUtc(),
      stores: rawStores is List
          ? rawStores
                .whereType<Map>()
                .map(
                  (entry) => CloudManifestStoreEntry.fromJson(
                    entry.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <CloudManifestStoreEntry>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'stores': stores.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}

DateTime? _tryParseDateTime(Object? raw) {
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw)?.toUtc();
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  return null;
}

int _toInt(Object? raw, {int fallback = 0}) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw) ?? fallback;
  }
  return fallback;
}
