import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/main_db/old/models/store_manifest.dart';

/// Результат сравнения локального и удалённого манифестов при snapshot sync.
enum StoreVersionCompareResult {
  /// Локальный и удалённый манифест относятся к разным хранилищам.
  differentStore,

  /// Манифесты совпадают.
  same,

  /// Локальная версия новее удалённой.
  localNewer,

  /// Удалённая версия новее локальной.
  remoteNewer,

  /// Версии расходятся, и автоматическое сравнение не даёт однозначного ответа.
  conflict,

  /// Удалённый манифест отсутствует.
  remoteMissing,
}

enum SnapshotSyncResultType { idle, noChanges, uploaded, downloaded, conflict }

/// Текущий этап выполнения snapshot sync.
enum SnapshotSyncStage {
  /// Подготовка локального snapshot перед синхронизацией.
  preparingLocalSnapshot,

  /// Проверка версии на удалённой стороне.
  checkingRemoteVersion,

  /// Передача основных файлов хранилища.
  transferringPrimaryFiles,

  /// Синхронизация вложений и дополнительных файлов.
  syncingAttachments,

  /// Обновление метаданных после передачи данных.
  updatingMetadata,

  /// Синхронизация завершена.
  completed,
}

enum SnapshotSyncTransferDirection { upload, download }

class SnapshotSyncTransferProgress {
  const SnapshotSyncTransferProgress({
    required this.direction,
    required this.completedFiles,
    required this.totalFiles,
    required this.transferredBytes,
    required this.totalBytes,
    this.currentFileName,
  });

  final SnapshotSyncTransferDirection direction;
  final int completedFiles;
  final int totalFiles;
  final int transferredBytes;
  final int? totalBytes;
  final String? currentFileName;

  bool get hasFileProgress => totalFiles > 0;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    if (transferredBytes <= 0) {
      return 0;
    }
    return (transferredBytes / total).clamp(0, 1).toDouble();
  }
}

typedef SnapshotSyncTransferProgressCallback =
    void Function(SnapshotSyncTransferProgress progress);

class SnapshotSyncProgress {
  const SnapshotSyncProgress({
    required this.stage,
    required this.stepIndex,
    required this.totalSteps,
    required this.title,
    required this.description,
    this.transferProgress,
  });

  final SnapshotSyncStage stage;
  final int stepIndex;
  final int totalSteps;
  final String title;
  final String description;
  final SnapshotSyncTransferProgress? transferProgress;
}

sealed class SnapshotSyncProgressEvent {
  const SnapshotSyncProgressEvent();
}

class SnapshotSyncProgressUpdate extends SnapshotSyncProgressEvent {
  const SnapshotSyncProgressUpdate(this.progress);

  final SnapshotSyncProgress progress;
}

class SnapshotSyncProgressResult extends SnapshotSyncProgressEvent {
  const SnapshotSyncProgressResult(this.result);

  final SnapshotSyncResult result;
}

class StoreSyncBinding {
  const StoreSyncBinding({
    required this.storeUuid,
    required this.tokenId,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  final String storeUuid;
  final String tokenId;
  final CloudSyncProvider provider;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StoreSyncBinding.fromJson(Map<String, dynamic> json) {
    return StoreSyncBinding(
      storeUuid: (json['storeUuid'] as String?)?.trim() ?? '',
      tokenId: (json['tokenId'] as String?)?.trim() ?? '',
      provider: _parseProvider(json['provider']) ?? CloudSyncProvider.other,
      createdAt: _tryParseDateTime(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _tryParseDateTime(json['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'storeUuid': storeUuid,
      'tokenId': tokenId,
      'provider': provider.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}

class SnapshotSyncConflict {
  const SnapshotSyncConflict({
    required this.localManifest,
    required this.remoteManifest,
  });

  final StoreManifest localManifest;
  final StoreManifest remoteManifest;
}

class SnapshotSyncResult {
  const SnapshotSyncResult({
    required this.type,
    this.localManifest,
    this.remoteManifest,
    this.conflict,
    this.requiresUnlockToApply = false,
  });

  final SnapshotSyncResultType type;
  final StoreManifest? localManifest;
  final StoreManifest? remoteManifest;
  final SnapshotSyncConflict? conflict;
  final bool requiresUnlockToApply;
}

class StoreSyncStatus {
  const StoreSyncStatus({
    required this.isStoreOpen,
    this.storePath,
    this.storeUuid,
    this.storeName,
    this.binding,
    this.token,
    this.localManifest,
    this.remoteManifest,
    this.compareResult = StoreVersionCompareResult.remoteMissing,
    this.pendingConflict,
    this.lastResultType = SnapshotSyncResultType.idle,
    this.requiresUnlockToApply = false,
    this.isApplyingRemoteUpdate = false,
    this.remoteCheckSkippedOffline = false,
    this.syncProgress,
    this.isSyncInProgress = false,
  });

  final bool isStoreOpen;
  final String? storePath;
  final String? storeUuid;
  final String? storeName;
  final StoreSyncBinding? binding;
  final AuthTokenEntry? token;
  final StoreManifest? localManifest;
  final StoreManifest? remoteManifest;
  final StoreVersionCompareResult compareResult;
  final SnapshotSyncConflict? pendingConflict;
  final SnapshotSyncResultType lastResultType;
  final bool requiresUnlockToApply;
  final bool isApplyingRemoteUpdate;
  final bool remoteCheckSkippedOffline;
  final SnapshotSyncProgress? syncProgress;
  final bool isSyncInProgress;

  StoreSyncStatus copyWith({
    bool? isStoreOpen,
    String? storePath,
    String? storeUuid,
    String? storeName,
    StoreSyncBinding? binding,
    bool clearBinding = false,
    AuthTokenEntry? token,
    bool clearToken = false,
    StoreManifest? localManifest,
    bool clearLocalManifest = false,
    StoreManifest? remoteManifest,
    bool clearRemoteManifest = false,
    StoreVersionCompareResult? compareResult,
    SnapshotSyncConflict? pendingConflict,
    bool clearPendingConflict = false,
    SnapshotSyncResultType? lastResultType,
    bool? requiresUnlockToApply,
    bool? isApplyingRemoteUpdate,
    bool? remoteCheckSkippedOffline,
    SnapshotSyncProgress? syncProgress,
    bool clearSyncProgress = false,
    bool? isSyncInProgress,
  }) {
    return StoreSyncStatus(
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      storePath: storePath ?? this.storePath,
      storeUuid: storeUuid ?? this.storeUuid,
      storeName: storeName ?? this.storeName,
      binding: clearBinding ? null : (binding ?? this.binding),
      token: clearToken ? null : (token ?? this.token),
      localManifest: clearLocalManifest
          ? null
          : (localManifest ?? this.localManifest),
      remoteManifest: clearRemoteManifest
          ? null
          : (remoteManifest ?? this.remoteManifest),
      compareResult: compareResult ?? this.compareResult,
      pendingConflict: clearPendingConflict
          ? null
          : (pendingConflict ?? this.pendingConflict),
      lastResultType: lastResultType ?? this.lastResultType,
      requiresUnlockToApply:
          requiresUnlockToApply ?? this.requiresUnlockToApply,
      isApplyingRemoteUpdate:
          isApplyingRemoteUpdate ?? this.isApplyingRemoteUpdate,
      remoteCheckSkippedOffline:
          remoteCheckSkippedOffline ?? this.remoteCheckSkippedOffline,
      syncProgress: clearSyncProgress
          ? null
          : (syncProgress ?? this.syncProgress),
      isSyncInProgress: isSyncInProgress ?? this.isSyncInProgress,
    );
  }
}

StoreVersionCompareResult compareStoreManifests({
  required StoreManifest local,
  required StoreManifest? remote,
}) {
  if (remote == null) {
    return StoreVersionCompareResult.remoteMissing;
  }
  if (local.storeUuid != remote.storeUuid) {
    return StoreVersionCompareResult.differentStore;
  }
  if (local.revision > remote.revision) {
    return StoreVersionCompareResult.localNewer;
  }
  if (remote.revision > local.revision) {
    return StoreVersionCompareResult.remoteNewer;
  }
  if (local.snapshotId.isNotEmpty && local.snapshotId == remote.snapshotId) {
    return StoreVersionCompareResult.same;
  }
  if (local.isSameContent(remote)) {
    return StoreVersionCompareResult.same;
  }
  return StoreVersionCompareResult.conflict;
}

CloudSyncProvider? _parseProvider(Object? raw) {
  if (raw is! String) {
    return null;
  }
  for (final provider in CloudSyncProvider.values) {
    if (provider.name == raw) {
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
