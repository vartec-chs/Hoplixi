import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/main_db/models/store_key_config.dart';
import 'package:hoplixi/main_db/services/vault_key_file_service.dart';

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
    int? lastMigrationVersion,
    String? appVersion,
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
    @Default(false) bool useKeyFile,
    String? keyFileId,
    String? keyFileHint,
    required StoreManifestContent content,
  }) = _StoreManifest;

  const StoreManifest._();

  factory StoreManifest.initial({
    required int lastMigrationVersion,
    required String appVersion,
    required String storeUuid,
    required String storeName,
    required DateTime updatedAt,
    required StoreManifestLastModifiedBy lastModifiedBy,
    StoreKeyConfig? keyConfig,
    bool useKeyFile = false,
    String? keyFileId,
    String? keyFileHint,
  }) {
    final keyFileSettings = StoreManifestKeyFileSettings.normalize(
      useKeyFile: useKeyFile,
      keyFileId: keyFileId,
      keyFileHint: keyFileHint,
    );
    return StoreManifest(
      lastMigrationVersion: lastMigrationVersion,
      appVersion: appVersion,
      storeUuid: storeUuid,
      storeName: storeName,
      revision: 0,
      updatedAt: updatedAt.toUtc(),
      snapshotId: '',
      lastModifiedBy: lastModifiedBy,
      keyConfig: keyConfig,
      useKeyFile: keyFileSettings.useKeyFile,
      keyFileId: keyFileSettings.keyFileId,
      keyFileHint: keyFileSettings.keyFileHint,
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
        lastMigrationVersion: null,
        appVersion: null,
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
        useKeyFile: false,
        keyFileId: null,
        keyFileHint: null,
        content: StoreManifestContent.empty(),
      );
    }

    final parsedLastModifiedBy = json['lastModifiedBy'] is Map<String, dynamic>
        ? StoreManifestLastModifiedBy.fromJson(
            json['lastModifiedBy'] as Map<String, dynamic>,
          )
        : const StoreManifestLastModifiedBy(
            deviceId: '',
            clientInstanceId: '',
            appVersion: '',
          );

    final keyFileSettings = StoreManifestKeyFileSettings.normalize(
      useKeyFile: json['useKeyFile'] as bool? ?? false,
      keyFileId: (json['keyFileId'] as String?)?.trim(),
      keyFileHint: json['keyFileHint'] as String?,
    );

    return StoreManifest(
      manifestVersion: _toInt(
        json['manifestVersion'],
        fallback: MainConstants.storeManifestVersion,
      ),
      lastMigrationVersion:
          _tryToNullableInt(json['lastMigrationVersion']) ??
          _tryToNullableInt(json['schemaVersion']),
      appVersion:
          (json['appVersion'] as String?)?.trim() ??
          (parsedLastModifiedBy.appVersion.isEmpty
              ? null
              : parsedLastModifiedBy.appVersion),
      storeUuid: (json['storeUuid'] as String?)?.trim() ?? '',
      storeName: (json['storeName'] as String?)?.trim() ?? '',
      revision: _toInt(json['revision']),
      updatedAt:
          _tryParseDateTime(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      snapshotId: (json['snapshotId'] as String?)?.trim() ?? '',
      baseRevision: _tryToNullableInt(json['baseRevision']),
      baseSnapshotId: (json['baseSnapshotId'] as String?)?.trim(),
      lastModifiedBy: parsedLastModifiedBy,
      sync: json['sync'] is Map<String, dynamic>
          ? StoreManifestSyncMetadata.fromJson(
              json['sync'] as Map<String, dynamic>,
            )
          : null,
      keyConfig: json['keyConfig'] is Map<String, dynamic>
          ? StoreKeyConfig.fromJson(json['keyConfig'] as Map<String, dynamic>)
          : null,
      useKeyFile: keyFileSettings.useKeyFile,
      keyFileId: keyFileSettings.keyFileId,
      keyFileHint: keyFileSettings.keyFileHint,
      content: json['content'] is Map<String, dynamic>
          ? StoreManifestContent.fromJson(
              json['content'] as Map<String, dynamic>,
            )
          : StoreManifestContent.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    final keyFileSettings = StoreManifestKeyFileSettings.normalize(
      useKeyFile: useKeyFile,
      keyFileId: keyFileId,
      keyFileHint: keyFileHint,
    );
    return <String, dynamic>{
      'manifestVersion': manifestVersion,
      'lastMigrationVersion': lastMigrationVersion,
      'appVersion': appVersion,
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
      'useKeyFile': keyFileSettings.useKeyFile,
      'keyFileId': keyFileSettings.keyFileId,
      'keyFileHint': keyFileSettings.keyFileHint,
      'content': content.toJson(),
    };
  }

  bool isSameContent(StoreManifest other) {
    return content.signature == other.content.signature &&
        keyConfig == other.keyConfig &&
        useKeyFile == other.useKeyFile &&
        keyFileId == other.keyFileId &&
        keyFileHint == other.keyFileHint;
  }

  int get version => manifestVersion;

  String get storeId => storeUuid;

  int get lastModified => updatedAt.millisecondsSinceEpoch;
}

typedef StoreManifestKeyFileSettingsRecord = ({
  bool useKeyFile,
  String? keyFileId,
  String? keyFileHint,
});

final class StoreManifestKeyFileSettings {
  const StoreManifestKeyFileSettings._();

  static StoreManifestKeyFileSettingsRecord normalize({
    required bool useKeyFile,
    String? keyFileId,
    String? keyFileHint,
  }) {
    if (!useKeyFile) {
      return (useKeyFile: false, keyFileId: null, keyFileHint: null);
    }

    final normalizedId = keyFileId?.trim();
    final normalizedHint = VaultKeyFileSecurity.sanitizeHint(keyFileHint);
    validate(
      useKeyFile: true,
      keyFileId: normalizedId,
      keyFileHint: normalizedHint,
    );
    return (
      useKeyFile: true,
      keyFileId: normalizedId,
      keyFileHint: normalizedHint,
    );
  }

  static void validate({
    required bool useKeyFile,
    String? keyFileId,
    String? keyFileHint,
  }) {
    if (useKeyFile && (keyFileId == null || keyFileId.trim().isEmpty)) {
      throw ArgumentError('keyFileId is required when useKeyFile is true');
    }
    if (keyFileHint != null &&
        VaultKeyFileSecurity.containsUnsafeHintMaterial(keyFileHint)) {
      throw ArgumentError('keyFileHint contains unsafe material');
    }
  }
}

extension StoreManifestKeyFileValidation on StoreManifest {
  void validateKeyFileSettings() {
    StoreManifestKeyFileSettings.validate(
      useKeyFile: useKeyFile,
      keyFileId: keyFileId,
      keyFileHint: keyFileHint,
    );
  }

  StoreManifest withoutKeyFile() {
    return copyWith(
      useKeyFile: false,
      keyFileId: null,
      keyFileHint: null,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  StoreManifest withKeyFile({
    required String keyFileId,
    String? keyFileHint,
    DateTime? updatedAt,
  }) {
    final normalized = StoreManifestKeyFileSettings.normalize(
      useKeyFile: true,
      keyFileId: keyFileId,
      keyFileHint: keyFileHint,
    );
    return copyWith(
      useKeyFile: normalized.useKeyFile,
      keyFileId: normalized.keyFileId,
      keyFileHint: normalized.keyFileHint,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }
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
