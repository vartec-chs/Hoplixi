import 'dart:async';

import 'package:yandex_drive_api/yandex_drive_api.dart';

import '../cloud_storage_api.dart';
import '../models/cloud_item.dart';
import '../models/cloud_page.dart';
import '../models/cloud_ref.dart';
import '../util/path_utils.dart';

class YandexDriveAdapter implements CloudStorageApi {
  final YandexDriveApi _api;

  YandexDriveAdapter(this._api);

  @override
  Future<CloudPage<CloudItem>> listChildren(
    CloudRef folder, {
    String? pageToken,
    int? pageSize,
  }) async {
    final folderPath = folder.requirePath();

    final offset = int.tryParse(pageToken ?? '') ?? 0;
    final limit = pageSize ?? 50;

    final res = await _api.getResource(
      folderPath,
      limit: limit,
      offset: offset,
    );

    final embedded = res.embedded;
    final items = (embedded?.items ?? const <Resource>[])
        .map(
          (e) => CloudItem(
            ref: CloudPath(e.path ?? cloudJoinPath(folderPath, e.name ?? '')),
            name: e.name ?? '',
            isFolder: e.type == 'dir',
            size: e.size,
            created: e.created,
            modified: e.modified,
          ),
        )
        .where((e) => e.name.isNotEmpty)
        .toList(growable: false);

    String? next;
    final total = embedded?.total;
    if (total != null && (offset + limit) < total) {
      next = (offset + limit).toString();
    }

    return CloudPage(items: items, nextToken: next);
  }

  @override
  Future<Stream<List<int>>> download(
    CloudRef file, {
    OAuth2ProgressCallback? onProgress,
  }) {
    return _api.downloadFile(file.requirePath(), onProgress: onProgress);
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

    if (contentLength == null) {
      throw ArgumentError('Yandex Disk upload requires contentLength');
    }

    await _api.uploadFile(
      fullPath,
      bytes,
      contentLength,
      overwrite: overwrite,
      onProgress: onProgress,
    );

    return CloudItem(ref: CloudPath(fullPath), name: name, isFolder: false);
  }

  @override
  Future<CloudItem> createFolder(CloudRef parentFolder, String name) async {
    final fullPath = cloudJoinPath(parentFolder.requirePath(), name);
    await _api.createFolder(fullPath);
    return CloudItem(ref: CloudPath(fullPath), name: name, isFolder: true);
  }

  @override
  Future<void> delete(CloudRef target, {bool? permanently}) {
    return _api.deleteResource(target.requirePath(), permanently: permanently);
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
    await _api.moveResource(fromPath, toPath);
  }

  @override
  Future<void> copy(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  }) async {
    final fromPath = from.requirePath();
    final destFolderPath = destinationFolder.requirePath();
    final name = newName ?? cloudBasename(fromPath);
    final toPath = cloudJoinPath(destFolderPath, name);
    await _api.copyResource(fromPath, toPath);
  }
}
