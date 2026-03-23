import 'dart:async';
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

class YandexDriveCloudStorageProvider implements CloudStorageProvider {
  YandexDriveCloudStorageProvider({
    required this.tokenId,
    required CloudSyncHttpTransport httpClient,
  }) : _httpClient = httpClient;

  static const String _baseUrl = 'https://cloud-api.yandex.net/v1/disk';
  static const Duration _operationPollInterval = Duration(milliseconds: 500);
  static const Duration _operationTimeout = Duration(minutes: 2);
  static const int _defaultPageSize = 100;

  final String tokenId;
  final CloudSyncHttpTransport _httpClient;

  @override
  CloudSyncProvider get provider => CloudSyncProvider.yandex;

  CloudResourceRef get rootRef => const CloudResourceRef.root(
    provider: CloudSyncProvider.yandex,
    path: 'disk:/',
  );

  @override
  Future<CloudResource> getResource(CloudResourceRef ref) async {
    final path = _requirePathRef(ref);
    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: '$_baseUrl/resources',
          queryParameters: <String, dynamic>{'path': path},
        ),
      );
      final json = _requireJsonMap(response.data);
      return _mapResource(json);
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to load Yandex resource.',
      );
    }
  }

  @override
  Future<CloudListPage> listFolder(
    CloudResourceRef folderRef, {
    String? cursor,
    int? pageSize,
  }) async {
    final path = _requirePathRef(folderRef);
    final folder = await getResource(folderRef);
    if (!folder.isFolder) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'CloudResourceRef must point to a folder for listFolder.',
        provider: provider,
      );
    }

    final limit = pageSize ?? _defaultPageSize;
    final offset = int.tryParse(cursor ?? '') ?? 0;

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: '$_baseUrl/resources',
          queryParameters: <String, dynamic>{
            'path': path,
            'limit': limit,
            'offset': offset,
          },
        ),
      );

      final json = _requireJsonMap(response.data);
      final embedded = _requireJsonMap(json['_embedded']);
      final rawItems = embedded['items'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => _mapResource(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const <CloudResource>[];

      final total = _toInt(embedded['total']);
      final embeddedOffset = _toInt(embedded['offset']) ?? offset;
      final embeddedLimit = _toInt(embedded['limit']) ?? limit;
      final nextOffset = embeddedOffset + embeddedLimit;
      final nextCursor = total != null && nextOffset < total
          ? nextOffset.toString()
          : null;

      return CloudListPage(items: items, nextCursor: nextCursor);
    } catch (error) {
      throw _mapError(error, fallbackMessage: 'Failed to list Yandex folder.');
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
          method: 'PUT',
          url: '$_baseUrl/resources',
          queryParameters: <String, dynamic>{'path': targetPath},
        ),
      );
      await _waitForOperationIfNeeded(response.data);
      return CloudFolder(
        await getResource(
          CloudResourceRef(provider: provider, path: targetPath),
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to create Yandex folder.',
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

    try {
      final uploadLink = await _getLink(
        path: targetPath,
        endpoint: '$_baseUrl/resources/upload',
        overwrite: overwrite,
      );

      await _httpClient.upload<dynamic>(
        CloudSyncUploadRequest(
          url: uploadLink.href,
          method: 'PUT',
          data: dataStream,
          cancelToken: cancelToken,
          onSendProgress: onProgress,
          options: Options(
            responseType: ResponseType.plain,
            contentType: contentType ?? 'application/octet-stream',
            headers: <String, dynamic>{
              HttpHeaders.contentLengthHeader: contentLength.toString(),
            },
          ),
        ),
      );

      return CloudFile(
        await getResource(
          CloudResourceRef(provider: provider, path: targetPath),
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to upload file to Yandex.',
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

    final path = _requirePathRef(fileRef);

    try {
      final downloadLink = await _getLink(
        path: path,
        endpoint: '$_baseUrl/resources/download',
      );

      await _httpClient.download(
        CloudSyncDownloadRequest(
          url: downloadLink.href,
          savePath: savePath,
          responseSink: responseSink,
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
        ),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to download file from Yandex.',
      );
    }
  }

  @override
  Future<CloudResource> copyResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final fromPath = _requirePathRef(sourceRef);
    final targetPath = await _buildTargetPath(target.parentRef, target.name);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_baseUrl/resources/copy',
          queryParameters: <String, dynamic>{
            'from': fromPath,
            'path': targetPath,
            'overwrite': overwrite.toString(),
          },
        ),
      );
      await _waitForOperationIfNeeded(response.data);
      return getResource(
        CloudResourceRef(provider: provider, path: targetPath),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to copy Yandex resource.',
      );
    }
  }

  @override
  Future<CloudResource> moveResource({
    required CloudResourceRef sourceRef,
    required CloudMoveCopyTarget target,
    bool overwrite = false,
  }) async {
    final fromPath = _requirePathRef(sourceRef);
    final targetPath = await _buildTargetPath(target.parentRef, target.name);

    try {
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'POST',
          url: '$_baseUrl/resources/move',
          queryParameters: <String, dynamic>{
            'from': fromPath,
            'path': targetPath,
            'overwrite': overwrite.toString(),
          },
        ),
      );
      await _waitForOperationIfNeeded(response.data);
      return getResource(
        CloudResourceRef(provider: provider, path: targetPath),
      );
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to move Yandex resource.',
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
      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'DELETE',
          url: '$_baseUrl/resources',
          queryParameters: <String, dynamic>{
            'path': path,
            'permanently': permanent.toString(),
          },
        ),
      );
      await _waitForOperationIfNeeded(response.data);
    } catch (error) {
      throw _mapError(
        error,
        fallbackMessage: 'Failed to delete Yandex resource.',
      );
    }
  }

  Future<_YandexLink> _getLink({
    required String path,
    required String endpoint,
    bool? overwrite,
  }) async {
    final response = await _httpClient.request<dynamic>(
      CloudSyncHttpRequest(
        method: 'GET',
        url: endpoint,
        queryParameters: <String, dynamic>{
          'path': path,
          if (overwrite != null) 'overwrite': overwrite.toString(),
        },
      ),
    );
    return _YandexLink.fromJson(_requireJsonMap(response.data));
  }

  Future<void> _waitForOperationIfNeeded(Object? payload) async {
    final operationId = _extractOperationId(payload);
    if (operationId == null) {
      return;
    }

    final deadline = DateTime.now().add(_operationTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_operationPollInterval);

      final response = await _httpClient.request<dynamic>(
        CloudSyncHttpRequest(
          method: 'GET',
          url: _buildOperationUrl(operationId),
          options: Options(responseType: ResponseType.json),
        ),
      );

      final json = _requireJsonMap(response.data);
      final status = (json['status'] as String?)?.trim();
      if (status == null || status.isEmpty) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.unknown,
          message: 'Yandex operation status is missing.',
          provider: provider,
        );
      }
      if (status == 'in-progress') {
        continue;
      }
      if (status == 'success') {
        return;
      }

      throw CloudStorageException(
        type: CloudStorageExceptionType.unknown,
        message: 'Yandex operation failed with status: $status',
        provider: provider,
        responseBodySnippet: response.data?.toString(),
      );
    }

    throw CloudStorageException(
      type: CloudStorageExceptionType.timeout,
      message: 'Timed out while waiting for Yandex async operation.',
      provider: provider,
    );
  }

  String _buildOperationUrl(String operationId) {
    if (operationId.startsWith('http://') ||
        operationId.startsWith('https://')) {
      return operationId;
    }
    return '$_baseUrl/operations/$operationId';
  }

  String? _extractOperationId(Object? payload) {
    if (payload is Map) {
      final raw = payload['operation_id'];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
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

    final parentPath = _requirePathRef(parentRef);
    if (!parentRef.isRoot) {
      final parent = await getResource(parentRef);
      if (!parent.isFolder) {
        throw CloudStorageException(
          type: CloudStorageExceptionType.invalidReference,
          message: 'Target parent must point to a folder.',
          provider: provider,
        );
      }
    }

    final base = parentPath == 'disk:/'
        ? parentPath
        : parentPath.replaceFirst(RegExp(r'/+$'), '');
    final suffix = normalizedName.replaceFirst(RegExp(r'^/+'), '');
    return base == 'disk:/' ? 'disk:/$suffix' : '$base/$suffix';
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
      return 'disk:/';
    }

    final rawPath = ref.path?.trim();
    if (rawPath == null || rawPath.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.invalidReference,
        message: 'Yandex resource references require path.',
        provider: provider,
      );
    }

    if (rawPath.startsWith('disk:/')) {
      return rawPath;
    }

    final normalized = rawPath.replaceFirst(RegExp(r'^/+'), '');
    return normalized.isEmpty ? 'disk:/' : 'disk:/$normalized';
  }

  CloudResource _mapResource(Map<String, dynamic> json) {
    final path = _normalizeReturnedPath(json['path'] as String?);
    final kind = (json['type'] as String?) == 'dir'
        ? CloudResourceKind.folder
        : CloudResourceKind.file;

    return CloudResource(
      ref: path == 'disk:/'
          ? const CloudResourceRef.root(
              provider: CloudSyncProvider.yandex,
              path: 'disk:/',
            )
          : CloudResourceRef(provider: provider, path: path),
      provider: provider,
      kind: kind,
      name: _extractName(
        path,
        fallback: kind == CloudResourceKind.folder ? '/' : 'resource',
      ),
      parentRef: _parentRefFromPath(path),
      metadata: CloudResourceMetadata(
        sizeBytes: _toInt(json['size']),
        mimeType: json['mime_type'] as String?,
        createdAt: _tryParseDate(json['created']),
        modifiedAt: _tryParseDate(json['modified']),
        hash: json['md5'] as String?,
        raw: json,
      ),
    );
  }

  CloudResourceRef? _parentRefFromPath(String path) {
    if (path == 'disk:/') {
      return null;
    }

    final trimmed = path.replaceFirst(RegExp(r'/+$'), '');
    final lastSlash = trimmed.lastIndexOf('/');
    if (lastSlash <= 'disk:'.length) {
      return rootRef;
    }

    final parentPath = trimmed.substring(0, lastSlash);
    return parentPath == 'disk:'
        ? rootRef
        : CloudResourceRef(provider: provider, path: parentPath);
  }

  String _normalizeReturnedPath(String? path) {
    if (path == null || path.trim().isEmpty || path.trim() == 'disk:') {
      return 'disk:/';
    }
    return path.trim();
  }

  String _extractName(String path, {required String fallback}) {
    if (path == 'disk:/') {
      return fallback;
    }

    final normalized = path.replaceFirst(RegExp(r'/+$'), '');
    final slashIndex = normalized.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == normalized.length - 1) {
      return fallback;
    }
    return normalized.substring(slashIndex + 1);
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
          final mappedType = switch (error.statusCode) {
            404 => CloudStorageExceptionType.notFound,
            409 => CloudStorageExceptionType.alreadyExists,
            429 => CloudStorageExceptionType.rateLimited,
            507 => CloudStorageExceptionType.quotaExceeded,
            _ => CloudStorageExceptionType.unknown,
          };
          return CloudStorageException(
            type: mappedType,
            message: fallbackMessage,
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
}

class _YandexLink {
  const _YandexLink({
    required this.href,
    this.method,
    this.templated,
    this.operationId,
  });

  final String href;
  final String? method;
  final bool? templated;
  final String? operationId;

  factory _YandexLink.fromJson(Map<String, dynamic> json) {
    final href = (json['href'] as String?)?.trim();
    if (href == null || href.isEmpty) {
      throw CloudStorageException(
        type: CloudStorageExceptionType.unknown,
        message: 'Yandex link response does not contain href.',
        provider: CloudSyncProvider.yandex,
        responseBodySnippet: json.toString(),
      );
    }

    return _YandexLink(
      href: href,
      method: json['method'] as String?,
      templated: json['templated'] as bool?,
      operationId: json['operation_id'] as String?,
    );
  }
}
