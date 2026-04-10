import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_download_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_upload_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_transport.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_file.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_folder.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_list_page.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_move_copy_target.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_kind.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_metadata.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_resource_ref.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider.dart';

class DropboxCloudStorageProvider implements CloudStorageProvider {
  DropboxCloudStorageProvider({
    required this.tokenId,
    required CloudSyncHttpTransport httpClient,
  }) : _httpClient = httpClient;

  static const String _apiBaseUrl = 'https://api.dropboxapi.com/2/files';
  static const String _contentBaseUrl =
      'https://content.dropboxapi.com/2/files';
  static const int _defaultPageSize = 100;
  static const int _simpleUploadLimitBytes = 150 * 1024 * 1024;
  static const int _uploadSessionChunkSizeBytes = 8 * 1024 * 1024;

  final String tokenId;
  final CloudSyncHttpTransport _httpClient;

  @override
  CloudSyncProvider get provider => CloudSyncProvider.dropbox;

  CloudResourceRef get rootRef => const CloudResourceRef.root(
    provider: CloudSyncProvider.dropbox,
    path: '',
  );

  @override
  Future<CloudResource> getResource(CloudResourceRef ref) async {
    if (ref.isRoot) {
      return _rootResource();
    }

    final path = _requirePathRef(ref);
    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/get_metadata',
          data: <String, dynamic>{'path': path, 'include_deleted': false},
          options: _metadataOptions(),
        ),
      );
      return _mapResource(_requireJsonMap(response.data));
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to load Dropbox resource.',
      );
    }
  }

  @override
  Future<CloudListPage> listFolder(
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  }) async {
    if (!folderRef.isRoot) {
      final folder = await getResource(folderRef);
      if (!folder.isFolder) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.invalidReference,
          message: 'CloudResourceRef must point to a folder for listFolder.',
          provider: provider,
        );
      }
    }

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: cursor == null || cursor.trim().isEmpty
              ? '$_apiBaseUrl/list_folder'
              : '$_apiBaseUrl/list_folder/continue',
          data: cursor == null || cursor.trim().isEmpty
              ? <String, dynamic>{
                  'path': _requirePathRef(folderRef),
                  'recursive': false,
                  'include_deleted': false,
                  'limit': pageSize ?? _defaultPageSize,
                }
              : <String, dynamic>{'cursor': cursor},
          options: _jsonOptions().copyWith(
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 5),
          ),
        ),
      );

      final json = _requireJsonMap(response.data);
      final entries = json['entries'];
      final items = entries is List
          ? entries
                .whereType<Map>()
                .map(
                  (item) => _mapResource(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <CloudResource>[];

      final nextCursor = json['has_more'] == true
          ? (json['cursor'] as String?)
          : null;

      return CloudListPage(items: items, nextCursor: nextCursor);
    } catch (error) {
      throw _mapError(error, fallbackMessage: 'Failed to list Dropbox folder.');
    }
  }

  @override
  Future<CloudFolder> createFolder({
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final targetPath = await _buildTargetPath(parentRef, name);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/create_folder_v2',
          data: <String, dynamic>{'path': targetPath, 'autorename': false},
          options: _jsonOptions(),
        ),
      );
      final payload = response.data;
      if (payload != null) {
        try {
          final json = _requireJsonMap(payload);
          final metadata = json['metadata'];
          if (metadata != null) {
            return CloudFolder(_mapResource(_requireJsonMap(metadata)));
          }
          if (json['path_display'] != null || json['path_lower'] != null) {
            return CloudFolder(_mapResource(json));
          }
        } catch (_) {
          // Ignore response body parsing issues here and fallback to reading the
          // created folder by path, since Dropbox may still have completed the
          // operation successfully.
        }
      }

      final createdResource = await getResource(
        CloudResourceRef(provider: provider, path: targetPath),
      );
      return CloudFolder(createdResource);
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to create Dropbox folder.',
      );
    }
  }

  @override
  Future<CloudFile> uploadFile({
    required CloudResourceRef parentRef,
    required String name,
    required Stream<List<int>> dataStream,
    required int contentLength,
    String? contentType,
    bool overwrite = false,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final targetPath = await _buildTargetPath(parentRef, name);
    _assertUploadTargetPath(
      parentRef: parentRef,
      name: name,
      targetPath: targetPath,
    );

    try {
      if (contentLength > _simpleUploadLimitBytes) {
        return await _uploadViaSession(
          targetPath: targetPath,
          dataStream: dataStream,
          contentLength: contentLength,
          contentType: contentType,
          overwrite: overwrite,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      }

      final response = await _httpClient.upload<dynamic>(
        CloudSyncUploadRequest(
          url: '$_contentBaseUrl/upload',
          method: 'POST',
          data: dataStream,
          cancelToken: cancelToken,
          onSendProgress: onProgress,
          options: _contentUploadOptions(
            apiArg: <String, dynamic>{
              'path': targetPath,
              'mode': overwrite ? 'overwrite' : 'add',
              'autorename': !overwrite,
              'mute': false,
              'strict_conflict': false,
            },
            contentType: contentType,
            contentLength: contentLength,
          ),
        ),
      );

      return CloudFile(_mapResource(_requireJsonMap(response.data)));
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to upload file to Dropbox at $targetPath.',
      );
    }
  }

  Future<CloudFile> _uploadViaSession({
    required String targetPath,
    required Stream<List<int>> dataStream,
    required int contentLength,
    required String? contentType,
    required bool overwrite,
    required ProgressCallback? onProgress,
    required CancelToken? cancelToken,
  }) async {
    final reader = _DropboxChunkedStreamReader(dataStream);

    try {
      final firstChunk = await reader.readChunk(
        _uploadSessionChunkSizeBytes,
        cancelToken,
      );
      if (firstChunk == null) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.unknown,
          message: 'Dropbox upload stream ended before any data was read.',
          provider: provider,
        );
      }

      final startResponse = await _httpClient.upload<dynamic>(
        CloudSyncUploadRequest(
          url: '$_contentBaseUrl/upload_session/start',
          method: 'POST',
          data: firstChunk,
          cancelToken: cancelToken,
          options: _contentUploadOptions(
            apiArg: const <String, dynamic>{'close': false},
            contentType: contentType,
            contentLength: firstChunk.length,
          ),
        ),
      );
      final startJson = _requireJsonMap(startResponse.data);
      final sessionId = (startJson['session_id'] as String?)?.trim();
      if (sessionId == null || sessionId.isEmpty) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.unknown,
          message: 'Dropbox upload session did not return a session_id.',
          provider: provider,
          responseBodySnippet: startResponse.data?.toString(),
        );
      }

      var uploaded = firstChunk.length;
      onProgress?.call(uploaded, contentLength);

      while (uploaded < contentLength) {
        final remaining = contentLength - uploaded;
        final chunk = await reader.readChunk(
          remaining < _uploadSessionChunkSizeBytes
              ? remaining
              : _uploadSessionChunkSizeBytes,
          cancelToken,
        );
        if (chunk == null || chunk.isEmpty) {
          throw CloudStorageException(
            type: CloudStorageExceptionType.unknown,
            message:
                'Dropbox upload stream ended before the declared contentLength was sent.',
            provider: provider,
          );
        }

        final isLastChunk = uploaded + chunk.length >= contentLength;
        if (isLastChunk) {
          final finishResponse = await _httpClient.upload<dynamic>(
            CloudSyncUploadRequest(
              url: '$_contentBaseUrl/upload_session/finish',
              method: 'POST',
              data: chunk,
              cancelToken: cancelToken,
              options: _contentUploadOptions(
                apiArg: <String, dynamic>{
                  'cursor': <String, dynamic>{
                    'session_id': sessionId,
                    'offset': uploaded,
                  },
                  'commit': <String, dynamic>{
                    'path': targetPath,
                    'mode': overwrite ? 'overwrite' : 'add',
                    'autorename': !overwrite,
                    'mute': false,
                    'strict_conflict': false,
                  },
                },
                contentType: contentType,
                contentLength: chunk.length,
              ),
            ),
          );
          uploaded += chunk.length;
          onProgress?.call(uploaded, contentLength);
          return CloudFile(_mapResource(_requireJsonMap(finishResponse.data)));
        }

        await _httpClient.upload<dynamic>(
          CloudSyncUploadRequest(
            url: '$_contentBaseUrl/upload_session/append_v2',
            method: 'POST',
            data: chunk,
            cancelToken: cancelToken,
            options: _contentUploadOptions(
              apiArg: <String, dynamic>{
                'cursor': <String, dynamic>{
                  'session_id': sessionId,
                  'offset': uploaded,
                },
                'close': false,
              },
              contentType: contentType,
              contentLength: chunk.length,
            ),
          ),
        );

        uploaded += chunk.length;
        onProgress?.call(uploaded, contentLength);
      }

      throw CloudStorageException(
        type: CloudStorageExceptionType.unknown,
        message: 'Dropbox upload session finished without a final commit.',
        provider: provider,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to upload file to Dropbox at $targetPath.',
      );
    } finally {
      await reader.cancel();
    }
  }

  @override
  Future<void> downloadFile({
    required CloudResourceRef fileRef,
    String? savePath,
    StreamConsumer<List<int>>? responseSink,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (savePath == null && responseSink == null) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'downloadFile requires savePath or responseSink.',
        provider: provider,
      );
    }
    if (savePath != null && responseSink != null) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'savePath and responseSink are mutually exclusive.',
        provider: provider,
      );
    }

    final path = _requirePathRef(fileRef);

    try {
      await _httpClient.download(
        CloudSyncDownloadRequest(
          url: '$_contentBaseUrl/download',
          savePath: savePath,
          responseSink: responseSink,
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
          headers: <String, dynamic>{
            'Dropbox-API-Arg': _encodeDropboxApiArg(<String, dynamic>{
              'path': path,
            }),
          },
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to download file from Dropbox.',
      );
    }
  }

  @override
  Future<CloudResource> copyResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final sourcePath = _requirePathRef(sourceRef);
    final targetPath = await _buildTargetPath(target.parentRef, target.name);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/copy_v2',
          data: <String, dynamic>{
            'from_path': sourcePath,
            'to_path': targetPath,
            'autorename': !overwrite,
            'allow_shared_folder': true,
            'allow_ownership_transfer': false,
          },
          options: _jsonOptions(),
        ),
      );
      final json = _requireJsonMap(response.data);
      return _mapResource(_requireJsonMap(json['metadata']));
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to copy Dropbox resource.',
      );
    }
  }

  @override
  Future<CloudResource> moveResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final sourcePath = _requirePathRef(sourceRef);
    final targetPath = await _buildTargetPath(target.parentRef, target.name);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/move_v2',
          data: <String, dynamic>{
            'from_path': sourcePath,
            'to_path': targetPath,
            'autorename': !overwrite,
            'allow_shared_folder': true,
            'allow_ownership_transfer': false,
          },
          options: _jsonOptions(),
        ),
      );
      final json = _requireJsonMap(response.data);
      return _mapResource(_requireJsonMap(json['metadata']));
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to move Dropbox resource.',
      );
    }
  }

  @override
  Future<void> deleteResource(
    CloudResourceRef ref, {
    bool permanent = true,
  }) async {
    final path = _requirePathRef(ref);

    try {
      await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/delete_v2',
          data: <String, dynamic>{'path': path},
          options: _jsonOptions(),
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to delete Dropbox resource.',
      );
    }
  }

  Future<String> _buildTargetPath(
    CloudResourceRef parentRef,
    String name,
  ) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'Target resource name cannot be empty.',
        provider: provider,
      );
    }

    String parentPath;
    if (parentRef.isRoot) {
      parentPath = '';
    } else {
      final rawParentPath = parentRef.path?.trim();
      if (rawParentPath != null && rawParentPath.isNotEmpty) {
        parentPath = _normalizePath(rawParentPath);
      } else {
        final parent = await getResource(parentRef);
        if (!parent.isFolder) {
          throw CloudStorageException(
            type: CloudStorageExceptionType.invalidReference,
            message: 'Target parent must point to a folder.',
            provider: provider,
          );
        }
        parentPath = _requirePathRef(parent.ref);
      }
    }

    if (!parentRef.isRoot && parentPath.startsWith('id:')) {
      final parent = await getResource(parentRef);
      if (!parent.isFolder) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.invalidReference,
          message: 'Target parent must point to a folder.',
          provider: provider,
        );
      }
      parentPath = _requirePathRef(parent.ref);
    }

    final base = parentPath.isEmpty
        ? ''
        : parentPath.replaceFirst(RegExp(r'/+$'), '');
    final suffix = normalizedName.replaceFirst(RegExp(r'^/+'), '');
    return base.isEmpty ? '/$suffix' : '$base/$suffix';
  }

  String _requirePathRef(CloudResourceRef ref) {
    if (ref.provider != provider) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'CloudResourceRef provider mismatch.',
        provider: provider,
      );
    }

    if (ref.isRoot) {
      return '';
    }

    final rawPath = ref.path?.trim();
    if (rawPath != null && rawPath.isNotEmpty) {
      return _normalizePath(rawPath);
    }

    final rawId = ref.resourceId?.trim();
    if (rawId != null && rawId.isNotEmpty) {
      return rawId;
    }

    throw CloudStorageException(
      type: CloudStorageExceptionType.invalidReference,
      message: 'Dropbox resource references require path or resourceId.',
      provider: provider,
    );
  }

  CloudResource _rootResource() {
    return CloudResource(
      ref: rootRef,
      provider: provider,
      kind: CloudResourceKind.folder,
      name: '/',
      metadata: const CloudResourceMetadata(),
    );
  }

  CloudResource _mapResource(Map<String, dynamic> json) {
    final tag = (json['.tag'] as String?)?.trim();
    final kind = switch (tag) {
      'folder' => CloudResourceKind.folder,
      'file' => CloudResourceKind.file,
      _ => CloudResourceKind.file,
    };
    final path = _normalizePath(
      (json['path_display'] as String?) ?? (json['path_lower'] as String?),
    );
    final ref = path.isEmpty
        ? rootRef
        : CloudResourceRef(
            provider: provider,
            resourceId: json['id'] as String?,
            path: path,
          );

    return CloudResource(
      ref: ref,
      provider: provider,
      kind: kind,
      name: _extractName(path, fallback: json['name'] as String? ?? '/'),
      parentRef: _parentRefFromPath(path),
      metadata: CloudResourceMetadata(
        sizeBytes: _toInt(json['size']),
        createdAt: _tryParseDate(json['client_modified']),
        modifiedAt: _tryParseDate(json['server_modified']),
        hash: json['content_hash'] as String?,
        raw: json,
      ),
    );
  }

  CloudResourceRef? _parentRefFromPath(String path) {
    if (path.isEmpty) {
      return null;
    }

    final normalized = path.replaceFirst(RegExp(r'/+$'), '');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash <= 0) {
      return rootRef;
    }

    return CloudResourceRef(
      provider: provider,
      path: normalized.substring(0, lastSlash),
    );
  }

  String _normalizePath(String? path) {
    if (path == null || path.trim().isEmpty || path.trim() == '/') {
      return '';
    }

    final trimmed = path.trim();
    if (trimmed.startsWith('id:')) {
      return trimmed;
    }

    final withoutTrailingSlash = trimmed.replaceFirst(RegExp(r'/+$'), '');
    return withoutTrailingSlash.startsWith('/')
        ? withoutTrailingSlash
        : '/$withoutTrailingSlash';
  }

  String _extractName(String path, {required String fallback}) {
    if (path.isEmpty) {
      return fallback;
    }

    final normalized = path.replaceFirst(RegExp(r'/+$'), '');
    final slashIndex = normalized.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == normalized.length - 1) {
      return fallback;
    }
    return normalized.substring(slashIndex + 1);
  }

  void _assertUploadTargetPath({
    required CloudResourceRef parentRef,
    required String name,
    required String targetPath,
  }) {
    final normalizedName = name.trim();
    final normalizedParentPath = _normalizePath(parentRef.path);
    if (normalizedName.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'Dropbox upload requires a non-empty file name.',
        provider: provider,
      );
    }

    if (targetPath.isEmpty || targetPath == normalizedParentPath) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message:
            'Dropbox upload target resolved to a folder path instead of a file path: '
            'parent=${normalizedParentPath.isEmpty ? "/" : normalizedParentPath}, '
            'name=$normalizedName, target=$targetPath',
        provider: provider,
      );
    }
  }

  DateTime? _tryParseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Options _contentUploadOptions({
    required Map<String, dynamic> apiArg,
    required String? contentType,
    required int contentLength,
  }) {
    const uploadContentType = 'application/octet-stream';
    return Options(
      responseType: ResponseType.json,
      contentType: uploadContentType,
      sendTimeout: const Duration(minutes: 15),
      receiveTimeout: const Duration(minutes: 15),
      headers: <String, dynamic>{
        'Dropbox-API-Arg': _encodeDropboxApiArg(apiArg),
        HttpHeaders.contentLengthHeader: contentLength.toString(),
      },
    );
  }

  Options _metadataOptions() => _jsonOptions().copyWith(
    connectTimeout: const Duration(minutes: 1),
    sendTimeout: const Duration(minutes: 1),
    receiveTimeout: const Duration(minutes: 5),
  );

  String _encodeDropboxApiArg(Map<String, dynamic> apiArg) {
    final json = jsonEncode(apiArg);
    final buffer = StringBuffer();

    for (final rune in json.runes) {
      if (rune <= 0x7F) {
        buffer.writeCharCode(rune);
        continue;
      }

      if (rune <= 0xFFFF) {
        buffer.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        continue;
      }

      final codePoint = rune - 0x10000;
      final highSurrogate = 0xD800 + (codePoint >> 10);
      final lowSurrogate = 0xDC00 + (codePoint & 0x3FF);
      buffer.write('\\u${highSurrogate.toRadixString(16).padLeft(4, '0')}');
      buffer.write('\\u${lowSurrogate.toRadixString(16).padLeft(4, '0')}');
    }

    return buffer.toString();
  }

  Map<String, dynamic> _requireJsonMap(Object? data) {
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        // Fall through to the generic error below.
      }
    }

    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw CloudStorageException(
      type: CloudStorageExceptionType.unknown,
      message: 'Cloud API returned an unexpected payload.',
      provider: provider,
      responseBodySnippet: data?.toString(),
    );
  }

  Options _jsonOptions() => Options(contentType: Headers.jsonContentType);

  CloudStorageException _mapError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is CloudStorageException) {
      return error;
    }

    if (error is _DropboxUploadCancelled) {
      return CloudStorageException(
        type: CloudStorageExceptionType.cancelled,
        message: 'Dropbox upload was cancelled.',
        provider: provider,
        cause: error,
      );
    }

    if (error is CloudSyncHttpException) {
      switch (error.type) {
        case CloudSyncHttpExceptionType.unauthorized:
        case CloudSyncHttpExceptionType.refreshFailed:
          return CloudStorageException(
            type: CloudStorageExceptionType.unauthorized,
            message: 'Cloud request is unauthorized.',
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
        case CloudSyncHttpExceptionType.network:
          return CloudStorageException(
            type: CloudStorageExceptionType.network,
            message: 'Cloud request failed due to a network error.',
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
        case CloudSyncHttpExceptionType.timeout:
          return CloudStorageException(
            type: CloudStorageExceptionType.timeout,
            message: 'Cloud request timed out.',
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
        case CloudSyncHttpExceptionType.cancelled:
          return CloudStorageException(
            type: CloudStorageExceptionType.cancelled,
            message: 'Cloud request was cancelled.',
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
        case CloudSyncHttpExceptionType.badResponse:
          final errorSummary = _extractDropboxErrorSummary(
            error.responseBodySnippet,
          );
          return CloudStorageException(
            type: _mapDropboxBadResponseType(
              statusCode: error.statusCode,
              errorSummary: errorSummary,
            ),
            message: errorSummary ?? fallbackMessage,
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
        case CloudSyncHttpExceptionType.misconfiguredProvider:
          return CloudStorageException(
            type: CloudStorageExceptionType.unsupportedOperation,
            message: error.message,
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
        case CloudSyncHttpExceptionType.tokenNotFound:
        case CloudSyncHttpExceptionType.unknown:
          return CloudStorageException(
            type: CloudStorageExceptionType.unknown,
            message: _buildUnknownMessage(fallbackMessage, error),
            provider: provider,
            statusCode: error.statusCode,
            requestUri: error.requestUri,
            responseBodySnippet: error.responseBodySnippet,
            cause: error,
          );
      }
    }

    return CloudStorageException(
      type: CloudStorageExceptionType.unknown,
      message: _buildUnknownMessage(fallbackMessage, error),
      provider: provider,
      cause: error,
    );
  }

  String _buildUnknownMessage(String fallbackMessage, Object? error) {
    final details = switch (error) {
      CloudSyncHttpException(responseBodySnippet: final snippet?)
          when snippet.trim().isNotEmpty =>
        snippet.trim(),
      _ => error?.toString(),
    };
    if (details == null || details.trim().isEmpty) {
      return fallbackMessage;
    }
    return '$fallbackMessage Cause: ${details.trim()}';
  }

  CloudStorageExceptionType _mapDropboxBadResponseType({
    required int? statusCode,
    required String? errorSummary,
  }) {
    switch (statusCode) {
      case 404:
        return CloudStorageExceptionType.notFound;
      case 409:
        if (errorSummary != null &&
            (errorSummary.contains('not_found') ||
                errorSummary.contains('path_lookup'))) {
          return CloudStorageExceptionType.notFound;
        }
        return CloudStorageExceptionType.alreadyExists;
      case 429:
        return CloudStorageExceptionType.rateLimited;
      case 507:
        return CloudStorageExceptionType.quotaExceeded;
      default:
        return CloudStorageExceptionType.unknown;
    }
  }

  String? _extractDropboxErrorSummary(String? responseBodySnippet) {
    if (responseBodySnippet == null || responseBodySnippet.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBodySnippet);
      if (decoded is Map) {
        final summary = decoded['error_summary'];
        if (summary is String && summary.trim().isNotEmpty) {
          return summary.trim();
        }
        final error = decoded['error'];
        if (error is Map) {
          final tag = error['.tag'];
          if (tag is String && tag.trim().isNotEmpty) {
            return tag.trim();
          }
        }
      }
    } catch (_) {
      return responseBodySnippet;
    }

    return responseBodySnippet;
  }
}

class _DropboxChunkedStreamReader {
  _DropboxChunkedStreamReader(Stream<List<int>> source)
    : _iterator = StreamIterator<List<int>>(source);

  final StreamIterator<List<int>> _iterator;
  final List<int> _buffer = <int>[];

  Future<List<int>?> readChunk(int maxBytes, CancelToken? cancelToken) async {
    if (maxBytes <= 0) {
      return null;
    }

    final bytes = <int>[];
    while (bytes.length < maxBytes) {
      if (cancelToken?.isCancelled == true) {
        throw const _DropboxUploadCancelled();
      }

      if (_buffer.isEmpty) {
        final hasNext = await _iterator.moveNext();
        if (!hasNext) {
          break;
        }
        _buffer.addAll(_iterator.current);
      }

      final remaining = maxBytes - bytes.length;
      final takeCount = remaining < _buffer.length ? remaining : _buffer.length;
      bytes.addAll(_buffer.take(takeCount));
      _buffer.removeRange(0, takeCount);
    }

    return bytes.isEmpty ? null : bytes;
  }

  Future<void> cancel() => _iterator.cancel();
}

class _DropboxUploadCancelled implements Exception {
  const _DropboxUploadCancelled();
}
