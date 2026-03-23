import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_file.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_folder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_list_page.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_move_copy_target.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider_factory.dart';

class CloudStorageRepository {
  const CloudStorageRepository(this._providerFactory);

  final CloudStorageProviderFactory _providerFactory;

  Future<CloudStorageProvider> providerForToken(String tokenId) {
    return _providerFactory.providerForToken(tokenId);
  }

  Future<CloudResource> getResource(
    String tokenId,
    CloudResourceRef ref,
  ) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    return provider.getResource(ref);
  }

  Future<CloudListPage> listFolder(
    String tokenId,
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    return provider.listFolder(folderRef, cursor: cursor, pageSize: pageSize);
  }

  Future<CloudFolder> createFolder(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    return provider.createFolder(parentRef: parentRef, name: name);
  }

  Future<CloudFile> uploadFile(
    String tokenId, {
    required CloudResourceRef parentRef,
    required String name,
    required Stream<List<int>> dataStream,
    required int contentLength,
    String? contentType,
    bool overwrite = false,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    return provider.uploadFile(
      parentRef: parentRef,
      name: name,
      dataStream: dataStream,
      contentLength: contentLength,
      contentType: contentType,
      overwrite: overwrite,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> downloadFile(
    String tokenId, {
    required CloudResourceRef fileRef,
    String? savePath,
    StreamConsumer<List<int>>? responseSink,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    await provider.downloadFile(
      fileRef: fileRef,
      savePath: savePath,
      responseSink: responseSink,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<CloudResource> copyResource(
    String tokenId, {
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    return provider.copyResource(
      sourceRef: sourceRef,
      target: target,
      overwrite: overwrite,
    );
  }

  Future<CloudResource> moveResource(
    String tokenId, {
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    return provider.moveResource(
      sourceRef: sourceRef,
      target: target,
      overwrite: overwrite,
    );
  }

  Future<void> deleteResource(
    String tokenId,
    CloudResourceRef ref, {
    bool permanent = true,
  }) async {
    final provider = await _providerFactory.providerForToken(tokenId);
    await provider.deleteResource(ref, permanent: permanent);
  }
}
