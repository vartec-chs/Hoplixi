import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_file.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_folder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_list_page.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_move_copy_target.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';

abstract interface class CloudStorageProvider {
  CloudSyncProvider get provider;

  Future<CloudResource> getResource(CloudResourceRef ref);

  Future<CloudListPage> listFolder(
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  });

  Future<CloudFolder> createFolder({
    required CloudResourceRef parentRef,
    required String name,
  });

  Future<CloudFile> uploadFile({
    required CloudResourceRef parentRef,
    required String name,
    required Stream<List<int>> dataStream,
    required int contentLength,
    String? contentType,
    bool overwrite = false,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<void> downloadFile({
    required CloudResourceRef fileRef,
    String? savePath,
    StreamConsumer<List<int>>? responseSink,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<CloudResource> copyResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  });

  Future<CloudResource> moveResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  });

  Future<void> deleteResource(CloudResourceRef ref, {bool permanent = true});
}
