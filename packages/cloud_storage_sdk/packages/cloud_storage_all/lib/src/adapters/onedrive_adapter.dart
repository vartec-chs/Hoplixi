import 'dart:async';

import 'package:onedrive_api/onedrive_rest_api.dart';

import '../cloud_storage_api.dart';
import '../models/cloud_item.dart';
import '../models/cloud_page.dart';
import '../models/cloud_ref.dart';
import '../util/path_utils.dart';

class OneDriveAdapter implements CloudStorageApi {
  final OneDriveApi _api;

  OneDriveAdapter(this._api);

  @override
  Future<CloudPage<CloudItem>> listChildren(
    CloudRef folder, {
    String? pageToken,
    int? pageSize,
  }) async {
    final folderPath = folder.requirePath();

    final res = await _api.listChildren(
      folderPath,
      nextLink: (pageToken?.isNotEmpty ?? false) ? pageToken : null,
      top: pageSize,
    );

    final items = res.value
        .map(
          (e) => CloudItem(
            ref: CloudPath(cloudJoinPath(folderPath, e.name)),
            name: e.name,
            isFolder: e.isFolder,
            size: e.size,
            created: e.createdDateTime,
            modified: e.lastModifiedDateTime,
          ),
        )
        .toList(growable: false);

    return CloudPage(items: items, nextToken: res.nextLink);
  }

  @override
  Future<Stream<List<int>>> download(
    CloudRef file, {
    OAuth2ProgressCallback? onProgress,
  }) {
    return _api.download(file.requirePath(), onProgress: onProgress);
  }

  @override
  Future<CloudItem> upload(
    CloudRef folder,
    String name,
    Stream<List<int>> bytes, {
    int? contentLength,
    String contentType = 'application/octet-stream',
    OAuth2ProgressCallback? onProgress,
    bool? overwrite,
  }) async {
    final fullPath = cloudJoinPath(folder.requirePath(), name);
    final created = await _api.upload(fullPath, bytes, onProgress: onProgress);

    return CloudItem(
      ref: CloudPath(fullPath),
      name: created.name,
      isFolder: created.isFolder,
      size: created.size,
      created: created.createdDateTime,
      modified: created.lastModifiedDateTime,
    );
  }

  @override
  Future<CloudItem> createFolder(CloudRef parentFolder, String name) async {
    final fullPath = cloudJoinPath(parentFolder.requirePath(), name);
    final created = await _api.createFolder(fullPath);

    return CloudItem(
      ref: CloudPath(fullPath),
      name: created.name,
      isFolder: true,
      created: created.createdDateTime,
      modified: created.lastModifiedDateTime,
    );
  }

  @override
  Future<void> delete(CloudRef target, {bool? permanently}) {
    return _api.delete(target.requirePath());
  }

  @override
  Future<void> move(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  }) async {
    final fromPath = from.requirePath();
    final destFolderPath = destinationFolder.requirePath();
    final name = newName ?? cloudBasename(fromPath);
    final toPath = cloudJoinPath(destFolderPath, name);
    await _api.move(fromPath, toPath);
  }

  @override
  Future<void> copy(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  }) {
    final fromPath = from.requirePath();
    final destFolderPath = destinationFolder.requirePath();
    final name = newName ?? cloudBasename(fromPath);
    final toPath = cloudJoinPath(destFolderPath, name);
    return _api.copy(fromPath, toPath);
  }
}
