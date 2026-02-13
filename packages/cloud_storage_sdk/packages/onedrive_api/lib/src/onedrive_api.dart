import 'dart:async';

import 'package:oauth2restclient/oauth2restclient.dart';

import 'interface.dart';
import 'models/models.dart';

class OneDriveRestApi implements OneDriveApi {
  final OAuth2RestClient client;
  static const String _baseUrl = 'https://graph.microsoft.com/v1.0';

  OneDriveRestApi(this.client);

  /// 경로를 URL 인코딩합니다.
  String _encodePath(String path) {
    // 경로의 각 세그먼트를 개별적으로 인코딩
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    final encodedSegments = segments.map(
      (segment) => Uri.encodeComponent(segment),
    );
    return encodedSegments.join('/');
  }

  /// 경로를 부모 경로와 이름으로 분리합니다.
  ///
  /// [path]는 분리할 경로입니다 (예: "/Documents/file.txt").
  /// Returns a tuple with (parentPath, name).
  (String, String) _splitPath(String path) {
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    if (segments.isEmpty) {
      throw ArgumentError('Invalid path: path cannot be empty');
    }

    final parentPath = segments.take(segments.length - 1).join('/');
    final name = segments.last;

    return (parentPath, name);
  }

  @override
  Future<Stream<List<int>>> download(
    String path, {
    OAuth2ProgressCallback? onProgress,
  }) async {
    final encodedPath = _encodePath(path);
    var url = '$_baseUrl/me/drive/root:/$encodedPath:/content';
    return await client.getStream(url, onProgress: onProgress);
  }

  @override
  Future<OneDriveDriveItems> listChildren(
    String path, {
    String? nextLink,
    int? top = 1000,
  }) async {
    String url;
    Map<String, String>? queryParams;

    if (nextLink != null) {
      url = nextLink;
    } else {
      final encodedPath = _encodePath(path);
      url =
          '$_baseUrl/me/drive/root${encodedPath.isEmpty ? '' : ':/$encodedPath:'}/children';

      if (top != null) {
        queryParams = {'$top': top.toString()};
      }
    }

    final response = await client.getJson(url, queryParams: queryParams);
    return OneDriveDriveItems.fromJson(response);
  }

  @override
  Future<OneDriveDriveItem> createFolder(String path) async {
    // path에서 부모 경로와 폴더명 분리
    final (parentPath, folderName) = _splitPath(path);

    final encodedPath = _encodePath(parentPath);
    var url =
        '$_baseUrl/me/drive/root${encodedPath.isEmpty ? '' : ':/$encodedPath:'}/children';

    final response = await client.postJson(
      url,
      body: OAuth2JsonBody({
        'name': folderName,
        'folder': {},
        '@microsoft.graph.conflictBehavior': 'rename',
      }),
    );
    return OneDriveDriveItem.fromJson(response);
  }

  @override
  Future<OneDriveDriveItem> upload(
    String path,
    Stream<List<int>> dataStream, {
    OAuth2ProgressCallback? onProgress,
  }) async {
    final chunks = await dataStream.toList();
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);

    final fileBody = OAuth2FileBody(
      Stream.fromIterable(chunks),
      contentLength: totalLength,
      contentType: 'application/octet-stream',
    );

    final encodedPath = _encodePath(path);
    final uploadUrl = '$_baseUrl/me/drive/root:/$encodedPath:/content';

    final response = await client.putJson(
      uploadUrl,
      body: fileBody,
      headers: {'Content-Type': 'application/octet-stream'},
      onProgress: onProgress,
    );

    return OneDriveDriveItem.fromJson(response);
  }

  @override
  Future<void> delete(String path) async {
    final encodedPath = _encodePath(path);
    await client.delete('$_baseUrl/me/drive/root:/$encodedPath:');
  }

  @override
  Future<OneDriveDriveItem> move(String path, String newPath) async {
    final encodedPath = _encodePath(path);

    // newPath에서 부모 경로와 파일명 분리
    final (newParentPath, newName) = _splitPath(newPath);

    final body = <String, dynamic>{};

    body['parentReference'] = {
      'path': newParentPath.isEmpty
          ? '/drive/root:'
          : '/drive/root:/$newParentPath',
    };

    if (newName.isNotEmpty) {
      body['name'] = newName;
    }

    final response = await client.patchJson(
      '$_baseUrl/me/drive/root:/$encodedPath:',
      body: OAuth2JsonBody(body),
    );
    return OneDriveDriveItem.fromJson(response);
  }

  @override
  Future<void> copy(String path, String newPath) async {
    final encodedPath = _encodePath(path);

    // newPath에서 부모 경로와 파일명 분리
    final (newParentPath, newName) = _splitPath(newPath);

    final body = <String, dynamic>{};

    body['parentReference'] = {
      'path': newParentPath.isEmpty
          ? '/drive/root:'
          : '/drive/root:$newParentPath',
    };

    if (newName.isNotEmpty) {
      body['name'] = newName;
    }

    var response = await client.post(
      '$_baseUrl/me/drive/root:/$encodedPath:/copy',
      body: OAuth2JsonBody(body),
    );

    response.ensureSuccess();
  }

  @override
  Future<OneDriveUser> getCurrentUser() async {
    final response = await client.getJson('$_baseUrl/me');
    return OneDriveUser.fromJson(response);
  }

  @override
  Future<OneDriveDrive> getDrive() async {
    final response = await client.getJson('$_baseUrl/me/drive');
    return OneDriveDrive.fromJson(response);
  }
}
