import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';

abstract final class SnapshotSyncUtils {
  static CloudResourceRef rootRefForProvider(CloudSyncProvider provider) {
    return switch (provider) {
      CloudSyncProvider.google => const CloudResourceRef.root(
          provider: CloudSyncProvider.google,
          resourceId: 'root',
          path: '',
        ),
      CloudSyncProvider.onedrive => const CloudResourceRef.root(
          provider: CloudSyncProvider.onedrive,
          resourceId: 'root',
          path: '',
        ),
      CloudSyncProvider.yandex => const CloudResourceRef.root(
          provider: CloudSyncProvider.yandex,
          path: 'disk:/',
        ),
      CloudSyncProvider.dropbox => const CloudResourceRef.root(
          provider: CloudSyncProvider.dropbox,
          path: '',
        ),
      CloudSyncProvider.other => const CloudResourceRef.root(
          provider: CloudSyncProvider.other,
          path: '',
        ),
    };
  }

  static CloudResourceRef? buildDirectChildRef(
    CloudResourceRef parentRef,
    String name,
  ) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return null;
    }

    return switch (parentRef.provider) {
      CloudSyncProvider.dropbox => CloudResourceRef(
          provider: CloudSyncProvider.dropbox,
          path: joinDropboxPath(parentRef.path, trimmedName),
        ),
      CloudSyncProvider.yandex => CloudResourceRef(
          provider: CloudSyncProvider.yandex,
          path: joinYandexPath(parentRef.path, trimmedName),
        ),
      _ => null,
    };
  }

  static String joinDropboxPath(String? parentPath, String childName) {
    final base = (parentPath ?? '').trim();
    final normalizedBase =
        base.isEmpty ? '' : base.replaceFirst(RegExp(r'/+$'), '');
    final normalizedChild = childName.replaceFirst(RegExp(r'^/+'), '');
    return normalizedBase.isEmpty
        ? '/$normalizedChild'
        : '$normalizedBase/$normalizedChild';
  }

  static String joinYandexPath(String? parentPath, String childName) {
    final base = (parentPath ?? 'disk:/').trim();
    final normalizedBase = base == 'disk:/'
        ? 'disk:/'
        : base.replaceFirst(RegExp(r'/+$'), '');
    final normalizedChild = childName.replaceFirst(RegExp(r'^/+'), '');
    return normalizedBase == 'disk:/'
        ? 'disk:/$normalizedChild'
        : '$normalizedBase/$normalizedChild';
  }

  static bool usesDirectPathOnly(CloudSyncProvider provider) {
    return switch (provider) {
      CloudSyncProvider.dropbox => true,
      CloudSyncProvider.yandex => true,
      _ => false,
    };
  }

  static bool shouldCreateFolderWithoutLookup(CloudResourceRef parentRef) {
    if (!usesDirectPathOnly(parentRef.provider)) {
      return false;
    }

    if (parentRef.isRoot) {
      return true;
    }

    final parentPath = parentRef.path?.trim();
    return parentPath != null && parentPath.isNotEmpty;
  }

  static bool shouldFallbackToListAfterDirectLookup(
    CloudSyncProvider provider,
    CloudStorageException error,
  ) {
    if (!usesDirectPathOnly(provider)) {
      return false;
    }

    return switch (error.type) {
      CloudStorageExceptionType.network => true,
      CloudStorageExceptionType.timeout => true,
      _ => false,
    };
  }

  static int resolveTransferredBytes(
    int current, {
    required int? reportedTotal,
    required int? fallbackTotal,
  }) {
    final safeCurrent = current < 0 ? 0 : current;
    final candidates = <int>[
      if (reportedTotal != null && reportedTotal > 0) reportedTotal,
      if (fallbackTotal != null && fallbackTotal > 0) fallbackTotal,
      safeCurrent,
    ];
    final upperBound = candidates.isEmpty
        ? safeCurrent
        : candidates.reduce((left, right) => left > right ? left : right);
    return safeCurrent.clamp(0, upperBound);
  }

  static CloudResourceRef? remoteStoreRefFromKnownLocation(
    CloudSyncProvider provider, {
    String? remoteStoreId,
    String? remotePath,
  }) {
    final normalizedId = remoteStoreId?.trim();
    final normalizedPath = remotePath?.trim();
    if ((normalizedId == null || normalizedId.isEmpty) &&
        (normalizedPath == null || normalizedPath.isEmpty)) {
      return null;
    }

    return CloudResourceRef(
      provider: provider,
      resourceId: normalizedId?.isEmpty == true ? null : normalizedId,
      path: normalizedPath?.isEmpty == true ? null : normalizedPath,
    );
  }

  static String layoutCacheKey(String tokenId, String storeUuid) {
    return '$tokenId::$storeUuid';
  }

  static String folderCacheKey(
    String tokenId,
    CloudResourceRef parentRef,
    String name,
  ) {
    final parentKey =
        '${parentRef.provider.id}|${parentRef.resourceId ?? ''}|${parentRef.path ?? ''}';
    return '$tokenId::$parentKey::$name';
  }
}

class ByteCollectorSink implements StreamConsumer<List<int>> {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  List<int> get bytes => _builder.takeBytes();

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _builder.add(chunk);
    }
  }

  @override
  Future<void> close() async {}
}
