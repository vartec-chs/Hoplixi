import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_download_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_upload_request.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_transport.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_refresh_service.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_resolver.dart';

class CloudSyncHttpClient implements CloudSyncHttpTransport {
  CloudSyncHttpClient({
    required this.tokenId,
    required this.provider,
    required CloudSyncTokenResolver tokenResolver,
    required CloudSyncTokenRefreshService tokenRefreshService,
    Dio? dio,
  }) : _tokenResolver = tokenResolver,
       _tokenRefreshService = tokenRefreshService {
    _dio = dio ?? Dio(_createBaseOptions());
    _retryDio = Dio(_copyBaseOptions(_dio.options))
      ..httpClientAdapter = _dio.httpClientAdapter
      ..transformer = _dio.transformer;

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: AppLogger.instance.dioLogPrint(tag: _logTag),
      ),
    );
    _retryDio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: AppLogger.instance.dioLogPrint(tag: _logTag),
      ),
    );

    _dio.interceptors.add(
      _CloudSyncAuthInterceptor(
        retryDio: _retryDio,
        tokenId: tokenId,
        provider: provider,
        tokenResolver: _tokenResolver,
        tokenRefreshService: _tokenRefreshService,
      ),
    );
  }

  static const String _logTag = 'CloudSyncHttpClient';

  static const String extraTokenIdKey = 'cloudSync.tokenId';
  static const String extraProviderKey = 'cloudSync.provider';
  static const String extraRetriedKey = 'cloudSync.retriedAfterRefresh';

  final String tokenId;
  final CloudSyncProvider provider;
  final CloudSyncTokenResolver _tokenResolver;
  final CloudSyncTokenRefreshService _tokenRefreshService;
  late final Dio _dio;
  late final Dio _retryDio;

  static BaseOptions _createBaseOptions() {
    return BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 2),
    );
  }

  static BaseOptions _copyBaseOptions(BaseOptions source) {
    return BaseOptions(
      method: source.method,
      baseUrl: source.baseUrl,
      queryParameters: Map<String, dynamic>.from(source.queryParameters),
      connectTimeout: source.connectTimeout,
      sendTimeout: source.sendTimeout,
      receiveTimeout: source.receiveTimeout,
      receiveDataWhenStatusError: source.receiveDataWhenStatusError,
      extra: Map<String, dynamic>.from(source.extra),
      headers: Map<String, dynamic>.from(source.headers),
      preserveHeaderCase: source.preserveHeaderCase,
      responseType: source.responseType,
      contentType: source.contentType,
      validateStatus: source.validateStatus,
      followRedirects: source.followRedirects,
      maxRedirects: source.maxRedirects,
      persistentConnection: source.persistentConnection,
      requestEncoder: source.requestEncoder,
      responseDecoder: source.responseDecoder,
      listFormat: source.listFormat,
    );
  }

  @override
  Future<Response<T>> request<T>(CloudSyncHttpRequest request) async {
    try {
      return await _dio.requestUri<T>(
        request.uri,
        data: request.data,
        cancelToken: request.cancelToken,
        options: request.toOptions(extra: _requestExtra()),
        onSendProgress: request.onSendProgress,
        onReceiveProgress: request.onReceiveProgress,
      );
    } on DioException catch (error, stackTrace) {
      throw _mapDioException(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<ResponseBody> download(CloudSyncDownloadRequest request) async {
    if (request.savePath != null && request.responseSink != null) {
      throw ArgumentError(
        'Provide either savePath or responseSink for CloudSyncDownloadRequest.',
      );
    }

    try {
      final response = await _dio.requestUri<ResponseBody>(
        request.uri,
        data: request.data,
        cancelToken: request.cancelToken,
        options: request.toOptions(extra: _requestExtra()),
      );
      final body = response.data;
      if (body == null) {
        throw CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.badResponse,
          message: 'Download response body is empty.',
          provider: provider,
          tokenId: tokenId,
          statusCode: response.statusCode,
          requestUri: request.uri,
        );
      }

      if (request.savePath != null) {
        return _persistDownloadToFile(body, request: request);
      }

      if (request.responseSink != null) {
        return _pipeDownloadToSink(body, request: request);
      }

      return body;
    } on DioException catch (error, stackTrace) {
      throw _mapDioException(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<Response<T>> upload<T>(CloudSyncUploadRequest request) async {
    try {
      return await _dio.requestUri<T>(
        request.uri,
        data: request.data,
        cancelToken: request.cancelToken,
        options: request.toOptions(extra: _requestExtra()),
        onSendProgress: request.onSendProgress,
        onReceiveProgress: request.onReceiveProgress,
      );
    } on DioException catch (error, stackTrace) {
      throw _mapDioException(error, stackTrace: stackTrace);
    }
  }

  @override
  void close({bool force = true}) {
    _dio.close(force: force);
  }

  Future<ResponseBody> _persistDownloadToFile(
    ResponseBody body, {
    required CloudSyncDownloadRequest request,
  }) async {
    final file = File(request.savePath!);
    await file.parent.create(recursive: true);
    final sink = file.openWrite();

    try {
      await _consumeResponseBody(
        body,
        onChunk: (chunk) async {
          sink.add(chunk);
        },
        onReceiveProgress: request.onReceiveProgress,
      );
    } catch (_) {
      await sink.close();
      rethrow;
    }

    await sink.flush();
    await sink.close();

    return ResponseBody.fromBytes(
      const <int>[],
      body.statusCode,
      statusMessage: body.statusMessage,
      headers: body.headers,
    );
  }

  Future<ResponseBody> _pipeDownloadToSink(
    ResponseBody body, {
    required CloudSyncDownloadRequest request,
  }) async {
    final chunks = <List<int>>[];

    try {
      await _consumeResponseBody(
        body,
        onChunk: (chunk) async {
          chunks.add(chunk);
        },
        onReceiveProgress: request.onReceiveProgress,
      );
      await request.responseSink!.addStream(
        Stream<List<int>>.fromIterable(chunks),
      );
    } finally {
      chunks.clear();
    }

    return ResponseBody.fromBytes(
      const <int>[],
      body.statusCode,
      statusMessage: body.statusMessage,
      headers: body.headers,
    );
  }

  Future<void> _consumeResponseBody(
    ResponseBody body, {
    required Future<void> Function(Uint8List chunk) onChunk,
    ProgressCallback? onReceiveProgress,
  }) async {
    var received = 0;
    final total = body.contentLength;

    await for (final chunk in body.stream) {
      received += chunk.length;
      await onChunk(chunk);
      onReceiveProgress?.call(received, total);
    }
  }

  Map<String, dynamic> _requestExtra() => <String, dynamic>{
    extraTokenIdKey: tokenId,
    extraProviderKey: provider.id,
    extraRetriedKey: false,
  };

  CloudSyncHttpException _mapDioException(
    DioException error, {
    required StackTrace stackTrace,
  }) {
    final nested = error.error;
    if (nested is CloudSyncHttpException) {
      return nested;
    }

    final snippet = CloudSyncHttpException.buildResponseBodySnippet(
      error.response?.data,
    );

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.timeout,
          message: 'Cloud API request timed out.',
          provider: provider,
          tokenId: tokenId,
          statusCode: error.response?.statusCode,
          requestUri: error.requestOptions.uri,
          responseBodySnippet: snippet,
          cause: error,
        );
      case DioExceptionType.cancel:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.cancelled,
          message: 'Cloud API request was cancelled.',
          provider: provider,
          tokenId: tokenId,
          requestUri: error.requestOptions.uri,
          cause: error,
        );
      case DioExceptionType.badResponse:
        final isUnauthorized = _isRefreshableUnauthorizedResponse(
          provider: provider,
          statusCode: error.response?.statusCode,
          responseData: error.response?.data,
        );
        final type = isUnauthorized
            ? CloudSyncHttpExceptionType.unauthorized
            : CloudSyncHttpExceptionType.badResponse;
        return CloudSyncHttpException(
          type: type,
          message: isUnauthorized
              ? 'Cloud API request is unauthorized.'
              : 'Cloud API returned an error response.',
          provider: provider,
          tokenId: tokenId,
          statusCode: error.response?.statusCode,
          requestUri: error.requestOptions.uri,
          responseBodySnippet: snippet,
          cause: error,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.network,
          message: 'Cloud API request failed due to a network error.',
          provider: provider,
          tokenId: tokenId,
          statusCode: error.response?.statusCode,
          requestUri: error.requestOptions.uri,
          responseBodySnippet: snippet,
          cause: error,
        );
      case DioExceptionType.unknown:
        logError(
          'Unexpected cloud sync HTTP error: $error',
          error: error,
          stackTrace: stackTrace,
          tag: _logTag,
        );
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.unknown,
          message: 'Unexpected cloud API error.',
          provider: provider,
          tokenId: tokenId,
          statusCode: error.response?.statusCode,
          requestUri: error.requestOptions.uri,
          responseBodySnippet: snippet,
          cause: error,
        );
    }
  }
}

bool _isRefreshableUnauthorizedResponse({
  required CloudSyncProvider provider,
  required int? statusCode,
  required Object? responseData,
}) {
  if (statusCode == 401) {
    return true;
  }

  if (provider == CloudSyncProvider.dropbox && statusCode == 400) {
    final summary = _extractDropboxErrorSummary(responseData);
    if (summary == null) {
      return false;
    }

    return summary.contains('expired_access_token') ||
        summary.contains('invalid_access_token');
  }

  return false;
}

String? _extractDropboxErrorSummary(Object? responseData) {
  if (responseData == null) {
    return null;
  }

  final payload = switch (responseData) {
    Map<String, dynamic> map => map,
    Map map => map.map((key, value) => MapEntry(key.toString(), value)),
    String text when text.trim().isNotEmpty => _decodeJsonMap(text.trim()),
    _ => null,
  };

  if (payload == null) {
    return null;
  }

  final summary = payload['error_summary'];
  if (summary is String && summary.trim().isNotEmpty) {
    return summary.trim();
  }

  final error = payload['error'];
  if (error is Map) {
    final tag = error['.tag'];
    if (tag is String && tag.trim().isNotEmpty) {
      return tag.trim();
    }
  }

  return null;
}

Map<String, dynamic>? _decodeJsonMap(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {
    return null;
  }

  return null;
}

class _CloudSyncAuthInterceptor extends QueuedInterceptor {
  _CloudSyncAuthInterceptor({
    required Dio retryDio,
    required String tokenId,
    required CloudSyncProvider provider,
    required CloudSyncTokenResolver tokenResolver,
    required CloudSyncTokenRefreshService tokenRefreshService,
  }) : _retryDio = retryDio,
       _tokenId = tokenId,
       _provider = provider,
       _tokenResolver = tokenResolver,
       _tokenRefreshService = tokenRefreshService;

  static const String _logTag = 'CloudSyncAuthInterceptor';

  final Dio _retryDio;
  final String _tokenId;
  final CloudSyncProvider _provider;
  final CloudSyncTokenResolver _tokenResolver;
  final CloudSyncTokenRefreshService _tokenRefreshService;

  Future<AuthTokenEntry>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenResolver.requireToken(_tokenId);
      final headers = <String, dynamic>{
        ...options.headers,
        HttpHeaders.authorizationHeader: _buildAuthorizationHeader(token),
      };
      final extra = <String, dynamic>{
        ...options.extra,
        CloudSyncHttpClient.extraTokenIdKey: _tokenId,
        CloudSyncHttpClient.extraProviderKey: _provider.id,
        CloudSyncHttpClient.extraRetriedKey:
            options.extra[CloudSyncHttpClient.extraRetriedKey] == true,
      };

      handler.next(options.copyWith(headers: headers, extra: extra));
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRefreshableUnauthorizedResponse(
      provider: _provider,
      statusCode: err.response?.statusCode,
      responseData: err.response?.data,
    )) {
      handler.next(err);
      return;
    }

    final alreadyRetried =
        err.requestOptions.extra[CloudSyncHttpClient.extraRetriedKey] == true;
    if (alreadyRetried) {
      handler.reject(
        _wrapAsDioException(
          err,
          CloudSyncHttpException(
            type: CloudSyncHttpExceptionType.unauthorized,
            message: 'Cloud API request remained unauthorized after retry.',
            provider: _provider,
            tokenId: _tokenId,
            statusCode: err.response?.statusCode,
            requestUri: err.requestOptions.uri,
            responseBodySnippet:
                CloudSyncHttpException.buildResponseBodySnippet(
                  err.response?.data,
                ),
            cause: err,
          ),
        ),
      );
      return;
    }

    try {
      final currentToken = await _tokenResolver.requireToken(_tokenId);
      final failedAuthHeader = err
          .requestOptions
          .headers[HttpHeaders.authorizationHeader]
          ?.toString();
      final currentAuthHeader = _buildAuthorizationHeader(currentToken);

      final tokenForRetry = failedAuthHeader == currentAuthHeader
          ? await _refreshTokenOnce()
          : currentToken;

      final retried = err.requestOptions.copyWith(
        headers: <String, dynamic>{
          ...err.requestOptions.headers,
          HttpHeaders.authorizationHeader: _buildAuthorizationHeader(
            tokenForRetry,
          ),
        },
        extra: <String, dynamic>{
          ...err.requestOptions.extra,
          CloudSyncHttpClient.extraRetriedKey: true,
        },
      );

      final response = await _retryDio.fetch<dynamic>(retried);
      handler.resolve(response);
    } catch (error, stackTrace) {
      final cloudError = error is CloudSyncHttpException
          ? error
          : error is DioException &&
                _isRefreshableUnauthorizedResponse(
                  provider: _provider,
                  statusCode: error.response?.statusCode,
                  responseData: error.response?.data,
                )
          ? CloudSyncHttpException(
              type: CloudSyncHttpExceptionType.unauthorized,
              message: 'Cloud API request remained unauthorized after retry.',
              provider: _provider,
              tokenId: _tokenId,
              statusCode: error.response?.statusCode,
              requestUri: error.requestOptions.uri,
              responseBodySnippet:
                  CloudSyncHttpException.buildResponseBodySnippet(
                    error.response?.data,
                  ),
              cause: error,
            )
          : CloudSyncHttpException(
              type: CloudSyncHttpExceptionType.unknown,
              message: 'Failed to refresh OAuth token for cloud request.',
              provider: _provider,
              tokenId: _tokenId,
              statusCode: err.response?.statusCode,
              requestUri: err.requestOptions.uri,
              responseBodySnippet:
                  CloudSyncHttpException.buildResponseBodySnippet(
                    err.response?.data,
                  ),
              cause: error,
            );

      logWarning(
        'Cloud request refresh failed: $cloudError',
        tag: _logTag,
        data: {'provider': _provider.id, 'tokenId': _tokenId},
      );

      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: cloudError,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<AuthTokenEntry> _refreshTokenOnce() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final refreshFuture = _tokenRefreshService.refreshToken(_tokenId);
    _refreshInFlight = refreshFuture;
    return refreshFuture.whenComplete(() {
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    });
  }

  DioException _wrapAsDioException(
    DioException source,
    CloudSyncHttpException cloudError,
  ) {
    return DioException(
      requestOptions: source.requestOptions,
      response: source.response,
      type: source.type,
      error: cloudError,
      stackTrace: source.stackTrace,
      message: source.message,
    );
  }

  String _buildAuthorizationHeader(AuthTokenEntry token) {
    final overrideScheme = _provider.metadata.apiAuthSchemeOverride?.trim();
    final tokenType = token.tokenType?.trim();
    final scheme = overrideScheme != null && overrideScheme.isNotEmpty
        ? overrideScheme
        : tokenType == null || tokenType.isEmpty
        ? 'Bearer'
        : tokenType;
    return '$scheme ${token.accessToken.trim()}';
  }
}
