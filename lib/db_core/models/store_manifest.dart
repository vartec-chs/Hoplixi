import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/db_core/models/store_key_config.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

part 'store_manifest.freezed.dart';

@freezed
sealed class StoreManifestLastModifiedBy with _$StoreManifestLastModifiedBy {
  const factory StoreManifestLastModifiedBy({
    required String deviceId,
    required String clientInstanceId,
    required String appVersion,
  }) = _StoreManifestLastModifiedBy;

  const StoreManifestLastModifiedBy._();

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
}

@freezed
sealed class StoreManifestSyncMetadata with _$StoreManifestSyncMetadata {
  const factory StoreManifestSyncMetadata({
    CloudSyncProvider? provider,
    String? remoteStoreId,
    String? remotePath,
    DateTime? syncedAt,
    String? providerRevisionTag,
  }) = _StoreManifestSyncMetadata;

  const StoreManifestSyncMetadata._();

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
}

@freezed
sealed class StoreManifestDbFileContent with _$StoreManifestDbFileContent {
  const factory StoreManifestDbFileContent({
    required String fileName,
    required int size,
    required String sha256,
    DateTime? modifiedAt,
  }) = _StoreManifestDbFileContent;

  const StoreManifestDbFileContent._();

  factory StoreManifestDbFileContent.fromJson(Map<String, dynamic> json) {
    return StoreManifestDbFileContent(
      fileName: (json['fileName'] as String?)?.trim() ?? '',
      size: _toInt(json['size']),
      sha256: (json['sha256'] as String?)?.trim() ?? '',
      modifiedAt: _tryParseDateTime(json['modifiedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'size': size,
      'sha256': sha256,
      'modifiedAt': modifiedAt?.toUtc().toIso8601String(),
    };
  }
}

@freezed
sealed class StoreManifestAttachmentsContent
    with _$StoreManifestAttachmentsContent {
  const factory StoreManifestAttachmentsContent({
    required int count,
    required int totalSize,
    required String manifestSha256,
    required String filesHash,
  }) = _StoreManifestAttachmentsContent;

  const StoreManifestAttachmentsContent._();

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
}

@freezed
sealed class StoreManifestContent with _$StoreManifestContent {
  const factory StoreManifestContent({
    required StoreManifestDbFileContent dbFile,
    required StoreManifestAttachmentsContent attachments,
  }) = _StoreManifestContent;

  const StoreManifestContent._();

  factory StoreManifestContent.empty() {
    return const StoreManifestContent(
      dbFile: StoreManifestDbFileContent(fileName: '', size: 0, sha256: ''),
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
      'attachments': attachments.toJson(),
    };
  }

  String get signature {
    return '${dbFile.sha256}:${attachments.manifestSha256}:${attachments.filesHash}';
  }
}

@freezed
sealed class StoreManifest with _$StoreManifest {
  const factory StoreManifest({
    @Default(MainConstants.storeManifestVersion) int manifestVersion,
    required String storeUuid,
    required String storeName,
    required int revision,
    required DateTime updatedAt,
    required String snapshotId,
    int? baseRevision,
    String? baseSnapshotId,
    required StoreManifestLastModifiedBy lastModifiedBy,
    StoreManifestSyncMetadata? sync,
    StoreKeyConfig? keyConfig,
    required StoreManifestContent content,
  }) = _StoreManifest;

  const StoreManifest._();

  factory StoreManifest.initial({
    required String storeUuid,
    required String storeName,
    required DateTime updatedAt,
    required StoreManifestLastModifiedBy lastModifiedBy,
    StoreKeyConfig? keyConfig,
  }) {
    return StoreManifest(
      storeUuid: storeUuid,
      storeName: storeName,
      revision: 0,
      updatedAt: updatedAt.toUtc(),
      snapshotId: '',
      lastModifiedBy: lastModifiedBy,
      keyConfig: keyConfig,
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
        manifestVersion: MainConstants.storeManifestVersion,
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
        keyConfig: null,
        content: StoreManifestContent.empty(),
      );
    }

    return StoreManifest(
      manifestVersion: _toInt(
        json['manifestVersion'],
        fallback: MainConstants.storeManifestVersion,
      ),
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
      keyConfig: json['keyConfig'] is Map<String, dynamic>
          ? StoreKeyConfig.fromJson(json['keyConfig'] as Map<String, dynamic>)
          : null,
      content: json['content'] is Map<String, dynamic>
          ? StoreManifestContent.fromJson(
              json['content'] as Map<String, dynamic>,
            )
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
      'keyConfig': keyConfig?.toJson(),
      'content': content.toJson(),
    };
  }

  bool isSameContent(StoreManifest other) {
    return content.signature == other.content.signature &&
        keyConfig == other.keyConfig;
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
