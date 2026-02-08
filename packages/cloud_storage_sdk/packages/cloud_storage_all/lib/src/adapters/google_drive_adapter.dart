import 'dart:async';

import 'package:google_drive_api/google_drive_api.dart';

import '../cloud_storage_api.dart';
import '../models/cloud_item.dart';
import '../models/cloud_page.dart';
import '../models/cloud_ref.dart';

class GoogleDriveAdapter implements CloudStorageApi {
  final GoogleDriveApi _api;

  GoogleDriveAdapter(this._api);

  @override
  Future<CloudPage<CloudItem>> listChildren(
    CloudRef folder, {
    String? pageToken,
    int? pageSize,
  }) async {
    final parentId = folder.requireId();

    final res = await _api.listFiles(
      parentId: parentId,
      pageSize: pageSize ?? 100,
      nextPageToken: (pageToken?.isNotEmpty ?? false) ? pageToken : null,
    );

    final items = (res.files ?? const <GDFile>[])
        .where(
          (f) => (f.id?.isNotEmpty ?? false) && (f.name?.isNotEmpty ?? false),
        )
        .map(
          (f) => CloudItem(
            ref: CloudId(f.id!),
            name: f.name!,
            isFolder: f.mimeType == 'application/vnd.google-apps.folder',
            size: int.tryParse(f.size ?? ''),
            created: f.createdTime,
            modified: f.modifiedTime,
          ),
        )
        .toList(growable: false);

    return CloudPage(items: items, nextToken: res.nextPageToken);
  }

  @override
  Future<Stream<List<int>>> download(
    CloudRef file, {
    OAuth2ProgressCallback? onProgress,
  }) {
    return _api.downloadFile(file.requireId(), onProgress: onProgress);
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
    final parentId = folder.requireId();

    if (contentLength == null) {
      throw ArgumentError('Google Drive upload requires contentLength');
    }

    final created = await _api.createFile(
      parentId,
      name,
      bytes,
      fileSize: contentLength,
      contentType: contentType,
      onProgress: onProgress,
    );

    return CloudItem(
      ref: CloudId(created.id!),
      name: created.name ?? name,
      isFolder: false,
      size: int.tryParse(created.size ?? ''),
      created: created.createdTime,
      modified: created.modifiedTime,
    );
  }

  @override
  Future<CloudItem> createFolder(CloudRef parentFolder, String name) async {
    final parentId = parentFolder.requireId();
    final created = await _api.createFolder(parentId, name);

    return CloudItem(
      ref: CloudId(created.id!),
      name: created.name ?? name,
      isFolder: true,
      created: created.createdTime,
      modified: created.modifiedTime,
    );
  }

  @override
  Future<void> delete(CloudRef target, {bool? permanently}) {
    return _api.delete(target.requireId());
  }

  @override
  Future<void> move(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  }) async {
    final fileId = from.requireId();
    final destFolderId = destinationFolder.requireId();

    final current = await _api.getFile(fileId);

    await _api.updateFile(
      fileId,
      fileName: newName,
      addParents: [destFolderId],
      removeParents: current.parents,
    );
  }

  @override
  Future<void> copy(
    CloudRef from,
    CloudRef destinationFolder, {
    String? newName,
  }) async {
    final fileId = from.requireId();
    final destFolderId = destinationFolder.requireId();

    final copied = await _api.copyFile(fileId, destFolderId);

    if (newName != null && (copied.id?.isNotEmpty ?? false)) {
      await _api.updateFile(copied.id!, fileName: newName);
    }
  }
}
