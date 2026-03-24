import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_download_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_upload_request.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_http_transport.dart';
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

class GoogleDriveCloudStorageProvider implements CloudStorageProvider {
  GoogleDriveCloudStorageProvider({
    required this.tokenId,
    required CloudSyncHttpTransport httpClient,
  }) : _httpClient = httpClient;

  static const String _apiBaseUrl = 'https://www.googleapis.com/drive/v3';
  static const String _uploadBaseUrl =
      'https://www.googleapis.com/upload/drive/v3';
  static const String _folderMimeType = 'application/vnd.google-apps.folder';
  static const int _defaultPageSize = 100;
  static const String _fileFields =
      'files(id,name,mimeType,size,createdTime,modifiedTime,md5Checksum,parents),nextPageToken';
  static const String _singleFileFields =
      'id,name,mimeType,size,createdTime,modifiedTime,md5Checksum,parents';

  final String tokenId;
  final CloudSyncHttpTransport _httpClient;

  @override
  CloudSyncProvider get provider => CloudSyncProvider.google;

  CloudResourceRef get rootRef => const CloudResourceRef.root(
    provider: CloudSyncProvider.google,
    resourceId: 'root',
    path: '',
  );

  @override
  Future<CloudResource> getResource(CloudResourceRef ref) async {
    if (ref.isRoot) {
      return _rootResource();
    }

    final fileId = _requireFileId(ref);
    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: '$_apiBaseUrl/files/$fileId',
          queryParameters: <String, dynamic>{
            'supportsAllDrives': true,
            'fields': _singleFileFields,
          },
        ),
      );

      return _mapResource(
        _requireJsonMap(response.data),
        fallbackPath: ref.path,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to load Google Drive resource.',
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

    final parentId = _folderId(folderRef);
    final parentPath = _normalizePath(folderRef.path);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: '$_apiBaseUrl/files',
          queryParameters: <String, dynamic>{
            'q': "'$parentId' in parents and trashed = false",
            'pageSize': pageSize ?? _defaultPageSize,
            if (cursor != null && cursor.trim().isNotEmpty) 'pageToken': cursor,
            'supportsAllDrives': true,
            'includeItemsFromAllDrives': true,
            'fields': _fileFields,
          },
        ),
      );

      final json = _requireJsonMap(response.data);
      final rawItems = json['files'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => _mapResource(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                    parentRef: folderRef,
                    parentPath: parentPath,
                  ),
                )
                .toList(growable: false)
          : const <CloudResource>[];

      return CloudListPage(
        items: items,
        nextCursor: json['nextPageToken'] as String?,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to list Google Drive folder.',
      );
    }
  }

  @override
  Future<CloudFolder> createFolder({
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final normalizedName = _normalizeTargetName(name);
    final parentId = _folderId(parentRef);
    final targetPath = _buildChildPath(parentRef.path, normalizedName);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/files',
          queryParameters: <String, dynamic>{
            'supportsAllDrives': true,
            'fields': _singleFileFields,
          },
          data: <String, dynamic>{
            'name': normalizedName,
            'mimeType': _folderMimeType,
            'parents': <String>[parentId],
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      return CloudFolder(
        _mapResource(
          _requireJsonMap(response.data),
          parentRef: parentRef,
          explicitPath: targetPath,
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to create Google Drive folder.',
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
    final normalizedName = _normalizeTargetName(name);
    final parentId = _folderId(parentRef);
    final targetPath = _buildChildPath(parentRef.path, normalizedName);

    try {
      final createdFile = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/files',
          queryParameters: <String, dynamic>{
            'supportsAllDrives': true,
            'fields': _singleFileFields,
          },
          data: <String, dynamic>{
            'name': normalizedName,
            'parents': <String>[parentId],
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      final createdJson = _requireJsonMap(createdFile.data);
      final fileId = createdJson['id'] as String?;
      if (fileId == null || fileId.trim().isEmpty) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.unknown,
          message:
              'Google Drive did not return a file id for the uploaded file.',
          provider: provider,
          responseBodySnippet: createdFile.data?.toString(),
        );
      }

      await _httpClient.upload<dynamic>(
        CloudSyncUploadRequest(
          url: '$_uploadBaseUrl/files/$fileId',
          method: 'PATCH',
          queryParameters: <String, dynamic>{
            'uploadType': 'media',
            'supportsAllDrives': true,
            'fields': _singleFileFields,
          },
          data: dataStream,
          cancelToken: cancelToken,
          onSendProgress: onProgress,
          options: Options(
            responseType: ResponseType.json,
            headers: <String, dynamic>{
              HttpHeaders.contentTypeHeader:
                  contentType ?? 'application/octet-stream',
              HttpHeaders.contentLengthHeader: contentLength.toString(),
            },
          ),
        ),
      );

      return CloudFile(
        await getResource(
          CloudResourceRef(
            provider: provider,
            resourceId: fileId,
            path: targetPath,
          ),
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to upload file to Google Drive.',
      );
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

    final fileId = _requireFileId(fileRef);

    try {
      await _httpClient.download(
        CloudSyncDownloadRequest(
          url: '$_apiBaseUrl/files/$fileId',
          savePath: savePath,
          responseSink: responseSink,
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
          queryParameters: <String, dynamic>{
            'alt': 'media',
            'supportsAllDrives': true,
          },
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to download file from Google Drive.',
      );
    }
  }

  @override
  Future<CloudResource> copyResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final sourceId = _requireFileId(sourceRef);
    final parentId = _folderId(target.parentRef);
    final targetName = _normalizeTargetName(target.name);
    final targetPath = _buildChildPath(target.parentRef.path, targetName);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_apiBaseUrl/files/$sourceId/copy',
          queryParameters: <String, dynamic>{
            'supportsAllDrives': true,
            'fields': _singleFileFields,
          },
          data: <String, dynamic>{
            'name': targetName,
            'parents': <String>[parentId],
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      return _mapResource(
        _requireJsonMap(response.data),
        parentRef: target.parentRef,
        explicitPath: targetPath,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to copy Google Drive resource.',
      );
    }
  }

  @override
  Future<CloudResource> moveResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final sourceResource = await getResource(sourceRef);
    final sourceId = _requireFileId(sourceRef);
    final parentId = _folderId(target.parentRef);
    final targetName = _normalizeTargetName(target.name);
    final targetPath = _buildChildPath(target.parentRef.path, targetName);
    final currentParents = _extractParents(sourceResource.metadata.raw);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'PATCH',
          url: '$_apiBaseUrl/files/$sourceId',
          queryParameters: <String, dynamic>{
            'supportsAllDrives': true,
            'addParents': parentId,
            if (currentParents.isNotEmpty)
              'removeParents': currentParents.join(','),
            'fields': _singleFileFields,
          },
          data: <String, dynamic>{'name': targetName},
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      return _mapResource(
        _requireJsonMap(response.data),
        parentRef: target.parentRef,
        explicitPath: targetPath,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to move Google Drive resource.',
      );
    }
  }

  @override
  Future<void> deleteResource(
    CloudResourceRef ref, {
    bool permanent = true,
  }) async {
    final fileId = _requireFileId(ref);

    try {
      await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'DELETE',
          url: '$_apiBaseUrl/files/$fileId',
          queryParameters: <String, dynamic>{'supportsAllDrives': true},
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to delete Google Drive resource.',
      );
    }
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

  CloudResource _mapResource(
    Map<String, dynamic> json, {
    CloudResourceRef? parentRef,
    String? parentPath,
    String? explicitPath,
    String? fallbackPath,
  }) {
    final mimeType = json['mimeType'] as String?;
    final kind = mimeType == _folderMimeType
        ? CloudResourceKind.folder
        : CloudResourceKind.file;
    final name = (json['name'] as String?)?.trim().isNotEmpty == true
        ? (json['name'] as String).trim()
        : (kind == CloudResourceKind.folder ? 'folder' : 'file');
    final resolvedPath =
        explicitPath ??
        _buildChildPath(parentPath ?? parentRef?.path, name) ??
        _normalizePath(fallbackPath);
    final fileId = (json['id'] as String?)?.trim();
    final effectiveParentRef =
        parentRef ?? _parentRefFromJson(json, parentPath: parentPath);

    return CloudResource(
      ref: CloudResourceRef(
        provider: provider,
        resourceId: fileId,
        path: resolvedPath,
      ),
      provider: provider,
      kind: kind,
      name: name,
      parentRef: effectiveParentRef,
      metadata: CloudResourceMetadata(
        sizeBytes: _toInt(json['size']),
        mimeType: mimeType,
        createdAt: _tryParseDate(json['createdTime']),
        modifiedAt: _tryParseDate(json['modifiedTime']),
        hash: json['md5Checksum'] as String?,
        raw: json,
      ),
    );
  }

  CloudResourceRef? _parentRefFromJson(
    Map<String, dynamic> json, {
    String? parentPath,
  }) {
    final parents = _extractParents(json);
    if (parents.isEmpty) {
      return rootRef;
    }

    final parentId = parents.first;
    if (parentId == 'root') {
      return rootRef;
    }

    return CloudResourceRef(
      provider: provider,
      resourceId: parentId,
      path: _normalizePath(parentPath),
    );
  }

  List<String> _extractParents(Map<String, dynamic> json) {
    final parents = json['parents'];
    if (parents is! List) {
      return const <String>[];
    }
    return parents
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _folderId(CloudResourceRef ref) {
    if (ref.isRoot) {
      return 'root';
    }

    final id = ref.resourceId?.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }

    throw CloudStorageException(
      type: CloudStorageExceptionType.invalidReference,
      message: 'Google Drive folder references require resourceId.',
      provider: provider,
    );
  }

  String _requireFileId(CloudResourceRef ref) {
    if (ref.provider != provider) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'CloudResourceRef provider mismatch.',
        provider: provider,
      );
    }

    if (ref.isRoot) {
      return 'root';
    }

    final id = ref.resourceId?.trim();
    if (id == null || id.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'Google Drive resource references require resourceId.',
        provider: provider,
      );
    }
    return id;
  }

  String _normalizeTargetName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'Target resource name cannot be empty.',
        provider: provider,
      );
    }
    return normalized;
  }

  String _normalizePath(String? path) {
    if (path == null || path.trim().isEmpty || path.trim() == '/') {
      return '';
    }

    final trimmed = path.trim();
    final normalized = trimmed.replaceFirst(RegExp(r'/+$'), '');
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  String? _buildChildPath(String? parentPath, String name) {
    final normalizedParentPath = _normalizePath(parentPath);
    final normalizedName = name.replaceFirst(RegExp(r'^/+'), '').trim();
    if (normalizedName.isEmpty) {
      return normalizedParentPath;
    }
    return normalizedParentPath.isEmpty
        ? '/$normalizedName'
        : '$normalizedParentPath/$normalizedName';
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

  Map<String, dynamic> _requireJsonMap(Object? data) {
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

  CloudStorageException _mapError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is CloudStorageException) {
      return error;
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
          final summary = _extractGoogleErrorSummary(error.responseBodySnippet);
          return CloudStorageException(
            type: _mapGoogleBadResponseType(
              statusCode: error.statusCode,
              errorSummary: summary,
            ),
            message: summary ?? fallbackMessage,
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
            message: fallbackMessage,
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
      message: fallbackMessage,
      provider: provider,
      cause: error,
    );
  }

  CloudStorageExceptionType _mapGoogleBadResponseType({
    required int? statusCode,
    required String? errorSummary,
  }) {
    final normalizedSummary = errorSummary?.toLowerCase();
    switch (statusCode) {
      case 404:
        return CloudStorageExceptionType.notFound;
      case 409:
        return CloudStorageExceptionType.alreadyExists;
      case 429:
        return CloudStorageExceptionType.rateLimited;
      case 403:
        if (normalizedSummary != null &&
            (normalizedSummary.contains('ratelimit') ||
                normalizedSummary.contains('too many requests'))) {
          return CloudStorageExceptionType.rateLimited;
        }
        if (normalizedSummary != null &&
            (normalizedSummary.contains('quota') ||
                normalizedSummary.contains('storage quota exceeded'))) {
          return CloudStorageExceptionType.quotaExceeded;
        }
        return CloudStorageExceptionType.unknown;
      default:
        return CloudStorageExceptionType.unknown;
    }
  }

  String? _extractGoogleErrorSummary(String? responseBodySnippet) {
    if (responseBodySnippet == null || responseBodySnippet.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBodySnippet);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          final message = error['message'];
          final status = error['status'];
          if (message is String && message.trim().isNotEmpty) {
            return status is String && status.trim().isNotEmpty
                ? '${message.trim()} ($status)'
                : message.trim();
          }
        }
      }
    } catch (_) {
      return responseBodySnippet;
    }

    return responseBodySnippet;
  }
}
