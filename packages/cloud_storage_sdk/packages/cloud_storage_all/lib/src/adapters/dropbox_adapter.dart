import 'dart:async';

import 'package:dropbox_api/dropbox_api.dart';

import '../cloud_storage_api.dart';
import '../models/cloud_item.dart';
import '../models/cloud_page.dart';
import '../models/cloud_ref.dart';
import '../util/path_utils.dart';

class DropboxAdapter implements CloudStorageApi {
  final DropboxApi _api;

  DropboxAdapter(this._api);

  @override
  Future<CloudPage<CloudItem>> listChildren(
    CloudRef folder, {
    String? pageToken,
    int? pageSize,
  }) async {
    final path = folder.requirePath();

    final DropboxFolderContents contents;
    if (pageToken?.isNotEmpty ?? false) {
      contents = await _api.listFolderContinue(pageToken!);
    } else {
      contents = await _api.listFolder(path, limit: pageSize ?? 200);
    }

    final items = contents.entries
        .map(
          (e) => CloudItem(
            ref: CloudPath(e.pathDisplay),
            name: e.name,
            isFolder: e.isFolder,
            size: e.size,
            created: e.clientModified,
            modified: e.serverModified,
          ),
        )
        .toList(growable: false);

    return CloudPage(
      items: items,
      nextToken: contents.hasMore ? contents.cursor : null,
    );
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

    final result = await _api.upload(
      fullPath,
      bytes,
      onProgress: onProgress,
      mode: (overwrite ?? false) ? 'overwrite' : 'add',
    );

    return CloudItem(
      ref: CloudPath(result.pathDisplay),
      name: result.name,
      isFolder: false,
      size: result.size,
      created: result.clientModified,
      modified: result.serverModified,
    );
  }

  @override
  Future<CloudItem> createFolder(CloudRef parentFolder, String name) async {
    final fullPath = cloudJoinPath(parentFolder.requirePath(), name);
    final created = await _api.createFolder(fullPath);
    return CloudItem(
      ref: CloudPath(created.pathDisplay),
      name: created.name,
      isFolder: true,
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
  }) {
    final fromPath = from.requirePath();
    final destFolderPath = destinationFolder.requirePath();
    final name = newName ?? cloudBasename(fromPath);
    final toPath = cloudJoinPath(destFolderPath, name);
    return _api.move(fromPath, toPath);
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
