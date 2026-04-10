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

class OneDriveCloudStorageProvider implements CloudStorageProvider {
  OneDriveCloudStorageProvider({
    required this.tokenId,
    required CloudSyncHttpTransport httpClient,
  }) : _httpClient = httpClient;

  static const String _baseUrl = 'https://graph.microsoft.com/v1.0/me/drive';
  static const String _folderFacetKey = 'folder';
  static const String _rootId = 'root';
  static const int _defaultPageSize = 100;
  static const Duration _copyPollInterval = Duration(milliseconds: 600);
  static const Duration _copyTimeout = Duration(minutes: 2);
  static const String _selectFields =
      'id,name,size,file,folder,parentReference,createdDateTime,lastModifiedDateTime,fileSystemInfo';

  final String tokenId;
  final CloudSyncHttpTransport _httpClient;

  String? _driveId;
  String? _resolvedRootItemId;

  @override
  CloudSyncProvider get provider => CloudSyncProvider.onedrive;

  CloudResourceRef get rootRef => const CloudResourceRef.root(
    provider: CloudSyncProvider.onedrive,
    resourceId: _rootId,
    path: '',
  );

  @override
  Future<CloudResource> getResource(CloudResourceRef ref) async {
    if (ref.isRoot) {
      return _getRootResource();
    }

    final itemId = _requireItemId(ref);
    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: '$_baseUrl/items/$itemId',
          queryParameters: <String, dynamic>{r'$select': _selectFields},
        ),
      );
      return _mapResource(
        _requireJsonMap(response.data),
        fallbackPath: ref.path,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to load OneDrive resource.',
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

    final parentPath = _normalizePath(folderRef.path);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: cursor == null || cursor.trim().isEmpty
              ? _childrenUrl(folderRef)
              : cursor.trim(),
          queryParameters: cursor == null || cursor.trim().isEmpty
              ? <String, dynamic>{
                  r'$top': pageSize ?? _defaultPageSize,
                  r'$select': _selectFields,
                }
              : null,
        ),
      );

      final json = _requireJsonMap(response.data);
      final rawItems = json['value'];
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
        nextCursor: json['@odata.nextLink'] as String?,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to list OneDrive folder.',
      );
    }
  }

  @override
  Future<CloudFolder> createFolder({
    required CloudResourceRef parentRef,
    required String name,
  }) async {
    final normalizedName = _normalizeTargetName(name);
    final targetPath = _buildChildPath(parentRef.path, normalizedName);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: _childrenUrl(parentRef),
          data: <String, dynamic>{
            'name': normalizedName,
            _folderFacetKey: <String, dynamic>{},
            '@microsoft.graph.conflictBehavior': 'rename',
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      return CloudFolder(
        _mapResource(
          _requireJsonMap(response.data),
          explicitPath: targetPath,
          parentRef: parentRef,
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to create OneDrive folder.',
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
    final targetPath = _buildChildPath(parentRef.path, normalizedName);

    try {
      final response = await _httpClient.upload<dynamic>(
        CloudSyncUploadRequest(
          url: _uploadUrl(parentRef, normalizedName),
          method: 'PUT',
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
        _mapResource(
          _requireJsonMap(response.data),
          explicitPath: targetPath,
          parentRef: parentRef,
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to upload file to OneDrive.',
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

    final itemId = _requireItemId(fileRef);

    try {
      await _httpClient.download(
        CloudSyncDownloadRequest(
          url: '$_baseUrl/items/$itemId/content',
          savePath: savePath,
          responseSink: responseSink,
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to download file from OneDrive.',
      );
    }
  }

  @override
  Future<CloudResource> copyResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final sourceId = _requireItemId(sourceRef);
    final targetFolder = await _resolveFolderResource(target.parentRef);
    final targetPath = _buildChildPath(target.parentRef.path, target.name);
    final driveId = await _ensureDriveId();

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_baseUrl/items/$sourceId/copy',
          queryParameters: <String, dynamic>{
            '@microsoft.graph.conflictBehavior': overwrite
                ? 'replace'
                : 'rename',
          },
          data: <String, dynamic>{
            'name': target.name.trim(),
            'parentReference': <String, dynamic>{
              'driveId': driveId,
              'id': _requireItemId(targetFolder.ref),
            },
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      await _waitForCopyOperation(response);
      return _findChildByName(
        parentRef: target.parentRef,
        childName: target.name.trim(),
        fallbackPath: targetPath ?? '',
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to copy OneDrive resource.',
      );
    }
  }

  @override
  Future<CloudResource> moveResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final sourceId = _requireItemId(sourceRef);
    final targetFolder = await _resolveFolderResource(target.parentRef);
    final targetPath = _buildChildPath(target.parentRef.path, target.name);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'PATCH',
          url: '$_baseUrl/items/$sourceId',
          queryParameters: <String, dynamic>{r'$select': _selectFields},
          data: <String, dynamic>{
            'name': target.name.trim(),
            'parentReference': <String, dynamic>{
              'id': _requireItemId(targetFolder.ref),
            },
          },
          options: Options(contentType: Headers.jsonContentType),
        ),
      );

      return _mapResource(
        _requireJsonMap(response.data),
        explicitPath: targetPath,
        parentRef: target.parentRef,
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to move OneDrive resource.',
      );
    }
  }

  @override
  Future<void> deleteResource(
    CloudResourceRef ref, {
    bool permanent = true,
  }) async {
    final itemId = _requireItemId(ref);

    try {
      await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(method: 'DELETE', url: '$_baseUrl/items/$itemId'),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to delete OneDrive resource.',
      );
    }
  }

  Future<CloudResource> _getRootResource() async {
    try {
      final response = await _httpClient.request<dynamic>(
        const CloudSyncHttpRequest(
          method: 'GET',
          url: '$_baseUrl/root',
          queryParameters: <String, dynamic>{r'$select': _selectFields},
        ),
      );
      final json = _requireJsonMap(response.data);
      _resolvedRootItemId ??= (json['id'] as String?)?.trim();
      _driveId ??= _extractDriveId(json);
      final resource = _mapResource(json, explicitPath: '');
      return resource;
    } catch (error) {
      throw _mapError(error, fallbackMessage: 'Failed to load OneDrive root.');
    }
  }

  Future<CloudResource> _resolveFolderResource(CloudResourceRef ref) async {
    if (ref.isRoot) {
      return _getRootResource();
    }
    final resource = await getResource(ref);
    if (!resource.isFolder) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'Target parent must point to a folder.',
        provider: provider,
      );
    }
    return resource;
  }

  Future<String> _ensureDriveId() async {
    if (_driveId != null && _driveId!.isNotEmpty) {
      return _driveId!;
    }

    final response = await _httpClient.request<dynamic>(
      const CloudSyncHttpRequest(
        method: 'GET',
        url: _baseUrl,
        queryParameters: <String, dynamic>{r'$select': 'id'},
      ),
    );
    final json = _requireJsonMap(response.data);
    final driveId = (json['id'] as String?)?.trim();
    if (driveId == null || driveId.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.unknown,
        message: 'OneDrive did not return driveId.',
        provider: provider,
        responseBodySnippet: response.data?.toString(),
      );
    }
    _driveId = driveId;
    return driveId;
  }

  Future<void> _waitForCopyOperation(Response<dynamic> response) async {
    final monitorUrl = response.headers.value(HttpHeaders.locationHeader);
    if (monitorUrl == null || monitorUrl.trim().isEmpty) {
      return;
    }

    final deadline = DateTime.now().add(_copyTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_copyPollInterval);
      final pollResponse = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(method: 'GET', url: monitorUrl),
      );

      if (pollResponse.statusCode == 202) {
        continue;
      }

      if (pollResponse.statusCode != null &&
          pollResponse.statusCode! >= 200 &&
          pollResponse.statusCode! < 300) {
        return;
      }

      throw CloudStorageException(
        type: CloudStorageExceptionType.unknown,
        message: 'OneDrive copy operation failed.',
        provider: provider,
        statusCode: pollResponse.statusCode,
        requestUri: pollResponse.realUri,
        responseBodySnippet: pollResponse.data?.toString(),
      );
    }

    throw CloudStorageException(
      type: CloudStorageExceptionType.timeout,
      message: 'Timed out while waiting for OneDrive copy operation.',
      provider: provider,
    );
  }

  Future<CloudResource> _findChildByName({
    required CloudResourceRef parentRef,
    required String childName,
    required String fallbackPath,
  }) async {
    String? cursor;
    do {
      final page = await listFolder(
        parentRef,
        cursor: cursor,
        pageSize: _defaultPageSize,
      );
      for (final item in page.items) {
        if (item.name == childName) {
          return item;
        }
      }
      cursor = page.nextCursor;
    } while (cursor != null && cursor.isNotEmpty);

    throw CloudStorageException(
      type: CloudStorageExceptionType.notFound,
      message: 'Copied OneDrive resource was not found after completion.',
      provider: provider,
      responseBodySnippet: fallbackPath,
    );
  }

  String _childrenUrl(CloudResourceRef ref) {
    if (ref.isRoot) {
      return '$_baseUrl/root/children';
    }
    final itemId = _requireItemId(ref);
    return '$_baseUrl/items/$itemId/children';
  }

  String _uploadUrl(CloudResourceRef parentRef, String name) {
    final encodedName = Uri.encodeComponent(name);
    if (parentRef.isRoot) {
      return '$_baseUrl/root:/$encodedName:/content';
    }
    final itemId = _requireItemId(parentRef);
    return '$_baseUrl/items/$itemId:/$encodedName:/content';
  }

  CloudResource _mapResource(
    Map<String, dynamic> json, {
    CloudResourceRef? parentRef,
    String? parentPath,
    String? explicitPath,
    String? fallbackPath,
  }) {
    final isFolder = json[_folderFacetKey] != null;
    final kind = isFolder ? CloudResourceKind.folder : CloudResourceKind.file;
    final rawName = (json['name'] as String?)?.trim();
    final name = rawName == null || rawName.isEmpty
        ? (kind == CloudResourceKind.folder ? 'folder' : 'file')
        : rawName;
    final pathFromParentReference = _extractPathFromParentReference(json);
    final resolvedPath =
        explicitPath ??
        _buildChildPath(
          pathFromParentReference ?? parentPath ?? parentRef?.path,
          name,
        ) ??
        _normalizePath(fallbackPath);
    final itemId = (json['id'] as String?)?.trim();
    final effectiveParentRef =
        parentRef ??
        _parentRefFromJson(json, parentPath: pathFromParentReference);

    return CloudResource(
      ref: CloudResourceRef(
        provider: provider,
        resourceId: itemId,
        path: resolvedPath,
        isRoot: resolvedPath.isEmpty,
      ),
      provider: provider,
      kind: kind,
      name: resolvedPath.isEmpty ? '/' : name,
      parentRef: resolvedPath.isEmpty ? null : effectiveParentRef,
      metadata: CloudResourceMetadata(
        sizeBytes: _toInt(json['size']),
        createdAt: _tryParseDate(json['createdDateTime']),
        modifiedAt: _tryParseDate(json['lastModifiedDateTime']),
        hash: _extractHash(json),
        raw: json,
      ),
    );
  }

  CloudResourceRef? _parentRefFromJson(
    Map<String, dynamic> json, {
    String? parentPath,
  }) {
    final parentReference = _extractParentReference(json);
    if (parentReference == null) {
      return rootRef;
    }

    final parentId = (parentReference['id'] as String?)?.trim();
    if (parentId == null ||
        parentId.isEmpty ||
        parentId == _resolvedRootItemId) {
      return rootRef;
    }

    return CloudResourceRef(
      provider: provider,
      resourceId: parentId,
      path: _normalizePath(parentPath),
    );
  }

  Map<String, dynamic>? _extractParentReference(Map<String, dynamic> json) {
    final raw = json['parentReference'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String? _extractPathFromParentReference(Map<String, dynamic> json) {
    final parentReference = _extractParentReference(json);
    if (parentReference == null) {
      return null;
    }

    final driveId = (parentReference['driveId'] as String?)?.trim();
    if (driveId != null && driveId.isNotEmpty) {
      _driveId ??= driveId;
    }

    final rawPath = parentReference['path'] as String?;
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }

    const prefix = '/drive/root:';
    final normalized = rawPath.trim();
    if (!normalized.startsWith(prefix)) {
      return null;
    }

    final relative = normalized.substring(prefix.length);
    return _normalizePath(relative);
  }

  String? _extractHash(Map<String, dynamic> json) {
    final fileFacet = json['file'];
    if (fileFacet is Map<String, dynamic>) {
      final hashes = fileFacet['hashes'];
      if (hashes is Map<String, dynamic>) {
        return (hashes['quickXorHash'] as String?) ??
            (hashes['sha1Hash'] as String?) ??
            (hashes['crc32Hash'] as String?);
      }
    } else if (fileFacet is Map) {
      final hashes = fileFacet['hashes'];
      if (hashes is Map) {
        return hashes['quickXorHash']?.toString() ??
            hashes['sha1Hash']?.toString() ??
            hashes['crc32Hash']?.toString();
      }
    }
    return null;
  }

  String? _extractDriveId(Map<String, dynamic> json) {
    final parentReference = _extractParentReference(json);
    return (parentReference?['driveId'] as String?)?.trim();
  }

  String _requireItemId(CloudResourceRef ref) {
    if (ref.provider != provider) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'CloudResourceRef provider mismatch.',
        provider: provider,
      );
    }

    if (ref.isRoot) {
      return _resolvedRootItemId ?? _rootId;
    }

    final id = ref.resourceId?.trim();
    if (id == null || id.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'OneDrive resource references require resourceId.',
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
    final normalizedParent = _normalizePath(parentPath);
    final normalizedName = name.replaceFirst(RegExp(r'^/+'), '').trim();
    if (normalizedName.isEmpty) {
      return normalizedParent;
    }
    return normalizedParent.isEmpty
        ? '/$normalizedName'
        : '$normalizedParent/$normalizedName';
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
          final summary = _extractOneDriveErrorSummary(
            error.responseBodySnippet,
          );
          return CloudStorageException(
            type: _mapOneDriveBadResponseType(
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

  CloudStorageExceptionType _mapOneDriveBadResponseType({
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
      case 507:
        return CloudStorageExceptionType.quotaExceeded;
      case 403:
        if (normalizedSummary != null &&
            (normalizedSummary.contains('quota') ||
                normalizedSummary.contains('insufficient'))) {
          return CloudStorageExceptionType.quotaExceeded;
        }
        return CloudStorageExceptionType.unknown;
      default:
        return CloudStorageExceptionType.unknown;
    }
  }

  String? _extractOneDriveErrorSummary(String? responseBodySnippet) {
    if (responseBodySnippet == null || responseBodySnippet.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBodySnippet);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          final message = error['message'];
          final code = error['code'];
          if (message is String && message.trim().isNotEmpty) {
            return code is String && code.trim().isNotEmpty
                ? '${message.trim()} ($code)'
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
