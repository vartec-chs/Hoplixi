import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class StoreManifestLastModifiedBy {
  const StoreManifestLastModifiedBy({
    required this.deviceId,
    required this.clientInstanceId,
    required this.appVersion,
  });

  final String deviceId;
  final String clientInstanceId;
  final String appVersion;

  factory StoreManifestLastModifiedBy.fromJson(Map<String, dynamic> json) {
    return StoreManifestLastModifiedBy(
      deviceId: (json['deviceId'] as String?)?.trim() ?? '',
      clientInstanceId: (json['clientInstanceId'] as String?)?.trim() ?? '',
      appVersion: (json['appVersion'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'clientInstanceId': clientInstanceId,
      'appVersion': appVersion,
    };
  }

  StoreManifestLastModifiedBy copyWith({
    String? deviceId,
    String? clientInstanceId,
    String? appVersion,
  }) {
    return StoreManifestLastModifiedBy(
      deviceId: deviceId ?? this.deviceId,
      clientInstanceId: clientInstanceId ?? this.clientInstanceId,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class StoreManifestSyncMetadata {
  const StoreManifestSyncMetadata({
    this.provider,
    this.remoteStoreId,
    this.remotePath,
    this.syncedAt,
    this.providerRevisionTag,
  });

  final CloudSyncProvider? provider;
  final String? remoteStoreId;
  final String? remotePath;
  final DateTime? syncedAt;
  final String? providerRevisionTag;

  factory StoreManifestSyncMetadata.fromJson(Map<String, dynamic> json) {
    return StoreManifestSyncMetadata(
      provider: _tryParseProvider(json['provider']),
      remoteStoreId: (json['remoteStoreId'] as String?)?.trim(),
      remotePath: (json['remotePath'] as String?)?.trim(),
      syncedAt: _tryParseDateTime(json['syncedAt']),
      providerRevisionTag: (json['providerRevisionTag'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider?.name,
      'remoteStoreId': remoteStoreId,
      'remotePath': remotePath,
      'syncedAt': syncedAt?.toUtc().toIso8601String(),
      'providerRevisionTag': providerRevisionTag,
    };
  }

  StoreManifestSyncMetadata copyWith({
    CloudSyncProvider? provider,
    String? remoteStoreId,
    String? remotePath,
    DateTime? syncedAt,
    String? providerRevisionTag,
    bool clearRemoteStoreId = false,
    bool clearRemotePath = false,
    bool clearSyncedAt = false,
    bool clearProviderRevisionTag = false,
  }) {
    return StoreManifestSyncMetadata(
      provider: provider ?? this.provider,
      remoteStoreId: clearRemoteStoreId
          ? null
          : (remoteStoreId ?? this.remoteStoreId),
      remotePath: clearRemotePath ? null : (remotePath ?? this.remotePath),
      syncedAt: clearSyncedAt ? null : (syncedAt ?? this.syncedAt),
      providerRevisionTag: clearProviderRevisionTag
          ? null
          : (providerRevisionTag ?? this.providerRevisionTag),
    );
  }
}

class StoreManifestDbFileContent {
  const StoreManifestDbFileContent({
    required this.fileName,
    required this.size,
    required this.sha256,
  });

  final String fileName;
  final int size;
  final String sha256;

  factory StoreManifestDbFileContent.fromJson(Map<String, dynamic> json) {
    return StoreManifestDbFileContent(
      fileName: (json['fileName'] as String?)?.trim() ?? '',
      size: _toInt(json['size']),
      sha256: (json['sha256'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'size': size,
      'sha256': sha256,
    };
  }

  StoreManifestDbFileContent copyWith({
    String? fileName,
    int? size,
    String? sha256,
  }) {
    return StoreManifestDbFileContent(
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      sha256: sha256 ?? this.sha256,
    );
  }
}

class StoreManifestKeyFileContent {
  const StoreManifestKeyFileContent({required this.sha256, required this.size});

  final String sha256;
  final int size;

  factory StoreManifestKeyFileContent.fromJson(Map<String, dynamic> json) {
    return StoreManifestKeyFileContent(
      sha256: (json['sha256'] as String?)?.trim() ?? '',
      size: _toInt(json['size']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'sha256': sha256, 'size': size};
  }

  StoreManifestKeyFileContent copyWith({String? sha256, int? size}) {
    return StoreManifestKeyFileContent(
      sha256: sha256 ?? this.sha256,
      size: size ?? this.size,
    );
  }
}

class StoreManifestAttachmentsContent {
  const StoreManifestAttachmentsContent({
    required this.count,
    required this.totalSize,
    required this.manifestSha256,
    required this.filesHash,
  });

  final int count;
  final int totalSize;
  final String manifestSha256;
  final String filesHash;

  factory StoreManifestAttachmentsContent.fromJson(Map<String, dynamic> json) {
    return StoreManifestAttachmentsContent(
      count: _toInt(json['count']),
      totalSize: _toInt(json['totalSize']),
      manifestSha256: (json['manifestSha256'] as String?)?.trim() ?? '',
      filesHash: (json['filesHash'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'count': count,
      'totalSize': totalSize,
      'manifestSha256': manifestSha256,
      'filesHash': filesHash,
    };
  }

  StoreManifestAttachmentsContent copyWith({
    int? count,
    int? totalSize,
    String? manifestSha256,
    String? filesHash,
  }) {
    return StoreManifestAttachmentsContent(
      count: count ?? this.count,
      totalSize: totalSize ?? this.totalSize,
      manifestSha256: manifestSha256 ?? this.manifestSha256,
      filesHash: filesHash ?? this.filesHash,
    );
  }
}

class StoreManifestContent {
  const StoreManifestContent({
    required this.dbFile,
    required this.keyFile,
    required this.attachments,
  });

  final StoreManifestDbFileContent dbFile;
  final StoreManifestKeyFileContent keyFile;
  final StoreManifestAttachmentsContent attachments;

  factory StoreManifestContent.empty() {
    return const StoreManifestContent(
      dbFile: StoreManifestDbFileContent(fileName: '', size: 0, sha256: ''),
      keyFile: StoreManifestKeyFileContent(sha256: '', size: 0),
      attachments: StoreManifestAttachmentsContent(
        count: 0,
        totalSize: 0,
        manifestSha256: '',
        filesHash: '',
      ),
    );
  }

  factory StoreManifestContent.fromJson(Map<String, dynamic> json) {
    return StoreManifestContent(
      dbFile: json['dbFile'] is Map<String, dynamic>
          ? StoreManifestDbFileContent.fromJson(
              json['dbFile'] as Map<String, dynamic>,
            )
          : const StoreManifestDbFileContent(fileName: '', size: 0, sha256: ''),
      keyFile: json['keyFile'] is Map<String, dynamic>
          ? StoreManifestKeyFileContent.fromJson(
              json['keyFile'] as Map<String, dynamic>,
            )
          : const StoreManifestKeyFileContent(sha256: '', size: 0),
      attachments: json['attachments'] is Map<String, dynamic>
          ? StoreManifestAttachmentsContent.fromJson(
              json['attachments'] as Map<String, dynamic>,
            )
          : const StoreManifestAttachmentsContent(
              count: 0,
              totalSize: 0,
              manifestSha256: '',
              filesHash: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dbFile': dbFile.toJson(),
      'keyFile': keyFile.toJson(),
      'attachments': attachments.toJson(),
    };
  }

  StoreManifestContent copyWith({
    StoreManifestDbFileContent? dbFile,
    StoreManifestKeyFileContent? keyFile,
    StoreManifestAttachmentsContent? attachments,
  }) {
    return StoreManifestContent(
      dbFile: dbFile ?? this.dbFile,
      keyFile: keyFile ?? this.keyFile,
      attachments: attachments ?? this.attachments,
    );
  }

  String get signature {
    return '${dbFile.sha256}:${keyFile.sha256}:${attachments.manifestSha256}:${attachments.filesHash}';
  }
}

class StoreManifest {
  const StoreManifest({
    this.manifestVersion = 2,
    required this.storeUuid,
    required this.storeName,
    required this.revision,
    required this.updatedAt,
    required this.snapshotId,
    this.baseRevision,
    this.baseSnapshotId,
    required this.lastModifiedBy,
    this.sync,
    required this.content,
  });

  final int manifestVersion;
  final String storeUuid;
  final String storeName;
  final int revision;
  final DateTime updatedAt;
  final String snapshotId;
  final int? baseRevision;
  final String? baseSnapshotId;
  final StoreManifestLastModifiedBy lastModifiedBy;
  final StoreManifestSyncMetadata? sync;
  final StoreManifestContent content;

  factory StoreManifest.initial({
    required String storeUuid,
    required String storeName,
    required DateTime updatedAt,
    required StoreManifestLastModifiedBy lastModifiedBy,
  }) {
    return StoreManifest(
      storeUuid: storeUuid,
      storeName: storeName,
      revision: 0,
      updatedAt: updatedAt.toUtc(),
      snapshotId: '',
      lastModifiedBy: lastModifiedBy,
      content: StoreManifestContent.empty(),
    );
  }

  factory StoreManifest.fromJson(Map<String, dynamic> json) {
    final hasLegacyShape =
        json.containsKey('storeId') ||
        json.containsKey('lastModified') ||
        !json.containsKey('storeUuid');
    if (hasLegacyShape) {
      final lastModified = _toInt(json['lastModified']);
      return StoreManifest(
        manifestVersion: 1,
        storeUuid: (json['storeId'] as String?)?.trim() ?? '',
        storeName: (json['storeName'] as String?)?.trim() ?? '',
        revision: 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          lastModified,
          isUtc: true,
        ),
        snapshotId: '',
        lastModifiedBy: const StoreManifestLastModifiedBy(
          deviceId: '',
          clientInstanceId: '',
          appVersion: '',
        ),
        content: StoreManifestContent.empty(),
      );
    }

    return StoreManifest(
      manifestVersion: _toInt(json['manifestVersion'], fallback: 2),
      storeUuid: (json['storeUuid'] as String?)?.trim() ?? '',
      storeName: (json['storeName'] as String?)?.trim() ?? '',
      revision: _toInt(json['revision']),
      updatedAt:
          _tryParseDateTime(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      snapshotId: (json['snapshotId'] as String?)?.trim() ?? '',
      baseRevision: _tryToNullableInt(json['baseRevision']),
      baseSnapshotId: (json['baseSnapshotId'] as String?)?.trim(),
      lastModifiedBy: json['lastModifiedBy'] is Map<String, dynamic>
          ? StoreManifestLastModifiedBy.fromJson(
              json['lastModifiedBy'] as Map<String, dynamic>,
            )
          : const StoreManifestLastModifiedBy(
              deviceId: '',
              clientInstanceId: '',
              appVersion: '',
            ),
      sync: json['sync'] is Map<String, dynamic>
          ? StoreManifestSyncMetadata.fromJson(
              json['sync'] as Map<String, dynamic>,
            )
          : null,
      content: json['content'] is Map<String, dynamic>
          ? StoreManifestContent.fromJson(json['content'] as Map<String, dynamic>)
          : StoreManifestContent.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'manifestVersion': manifestVersion,
      'storeUuid': storeUuid,
      'storeName': storeName,
      'revision': revision,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'snapshotId': snapshotId,
      'baseRevision': baseRevision,
      'baseSnapshotId': baseSnapshotId,
      'lastModifiedBy': lastModifiedBy.toJson(),
      'sync': sync?.toJson(),
      'content': content.toJson(),
    };
  }

  StoreManifest copyWith({
    int? manifestVersion,
    String? storeUuid,
    String? storeName,
    int? revision,
    DateTime? updatedAt,
    String? snapshotId,
    int? baseRevision,
    String? baseSnapshotId,
    bool clearBaseRevision = false,
    bool clearBaseSnapshotId = false,
    StoreManifestLastModifiedBy? lastModifiedBy,
    StoreManifestSyncMetadata? sync,
    bool clearSync = false,
    StoreManifestContent? content,
  }) {
    return StoreManifest(
      manifestVersion: manifestVersion ?? this.manifestVersion,
      storeUuid: storeUuid ?? this.storeUuid,
      storeName: storeName ?? this.storeName,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
      snapshotId: snapshotId ?? this.snapshotId,
      baseRevision: clearBaseRevision
          ? null
          : (baseRevision ?? this.baseRevision),
      baseSnapshotId: clearBaseSnapshotId
          ? null
          : (baseSnapshotId ?? this.baseSnapshotId),
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      sync: clearSync ? null : (sync ?? this.sync),
      content: content ?? this.content,
    );
  }

  bool isSameContent(StoreManifest other) {
    return content.signature == other.content.signature;
  }

  int get version => manifestVersion;

  String get storeId => storeUuid;

  int get lastModified => updatedAt.millisecondsSinceEpoch;
}

CloudSyncProvider? _tryParseProvider(Object? raw) {
  final value = (raw as String?)?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  for (final provider in CloudSyncProvider.values) {
    if (provider.name == value) {
      return provider;
    }
  }

  return null;
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

int? _tryToNullableInt(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is String) {
    return int.tryParse(raw);
  }
  return null;
}
