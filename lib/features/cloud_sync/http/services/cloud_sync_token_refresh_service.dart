import 'package:dio/dio.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/services/app_credentials_service.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_resolver.dart';

class CloudSyncTokenRefreshService {
  CloudSyncTokenRefreshService({
    required CloudSyncTokenResolver tokenResolver,
    required AppCredentialsService appCredentialsService,
    Dio? refreshDio,
  }) : _tokenResolver = tokenResolver,
       _appCredentialsService = appCredentialsService,
       _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 30),
             ),
           ) {
    _refreshDio.interceptors.add(
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
  }

  static const String _logTag = 'CloudSyncTokenRefreshService';

  final CloudSyncTokenResolver _tokenResolver;
  final AppCredentialsService _appCredentialsService;
  final Dio _refreshDio;

  Future<AuthTokenEntry> refreshToken(String tokenId) async {
    final token = await _tokenResolver.requireToken(tokenId);
    final tokenEndpoint = token.provider.metadata.tokenEndpoint;
    if (tokenEndpoint == null || tokenEndpoint.trim().isEmpty) {
      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.misconfiguredProvider,
        message: 'OAuth token endpoint is missing for this provider.',
        provider: token.provider,
        tokenId: tokenId,
      );
    }

    if (!token.hasRefreshToken) {
      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.refreshFailed,
        message: 'Refresh token is missing for this OAuth token.',
        provider: token.provider,
        tokenId: tokenId,
      );
    }

    final credential = await _loadCredentialForToken(token);
    final payload = await _requestRefreshPayload(
      token: token,
      credential: credential,
      tokenEndpoint: Uri.parse(tokenEndpoint),
    );

    final refreshedToken = token.copyWith(
      accessToken: _requireAccessToken(payload, token),
      refreshToken:
          _normalizeString(payload['refresh_token']) ?? token.refreshToken,
      tokenType: _normalizeString(payload['token_type']) ?? token.tokenType,
      expiresAt: _resolveExpiresAt(payload['expires_in']) ?? token.expiresAt,
      scopes: _extractScopes(payload['scope']).isEmpty
          ? token.scopes
          : _extractScopes(payload['scope']),
      extraData: _buildExtraData(payload, previous: token.extraData),
    );

    final saved = await _tokenResolver.saveToken(refreshedToken);
    logInfo(
      'Refreshed OAuth token ${saved.id} (${saved.provider.id})',
      tag: _logTag,
    );
    return saved;
  }

  Future<Map<String, dynamic>> _requestRefreshPayload({
    required AuthTokenEntry token,
    required AppCredentialEntry credential,
    required Uri tokenEndpoint,
  }) async {
    try {
      final response = await _refreshDio.postUri<dynamic>(
        tokenEndpoint,
        data: <String, dynamic>{
          'grant_type': 'refresh_token',
          'refresh_token': token.refreshToken!.trim(),
          'client_id': credential.clientId.trim(),
          if (credential.clientSecret != null &&
              credential.clientSecret!.trim().isNotEmpty)
            'client_secret': credential.clientSecret!.trim(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );

      final data = response.data;
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }

      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.refreshFailed,
        message: 'Refresh endpoint returned an unexpected payload.',
        provider: token.provider,
        tokenId: token.id,
        requestUri: tokenEndpoint,
      );
    } on DioException catch (error, stackTrace) {
      throw _mapRefreshError(
        error,
        stackTrace: stackTrace,
        token: token,
        tokenEndpoint: tokenEndpoint,
      );
    }
  }

  Future<AppCredentialEntry> _loadCredentialForToken(
    AuthTokenEntry token,
  ) async {
    await _appCredentialsService.initialize();

    final credentialId = token.appCredentialId?.trim();
    if (credentialId == null || credentialId.isEmpty) {
      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.misconfiguredProvider,
        message: 'OAuth token is not linked to an app credential.',
        provider: token.provider,
        tokenId: token.id,
      );
    }

    final credential = await _appCredentialsService.getById(credentialId);
    if (credential == null) {
      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.misconfiguredProvider,
        message: 'App credential for this token was not found.',
        provider: token.provider,
        tokenId: token.id,
      );
    }

    if (credential.clientId.trim().isEmpty) {
      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.misconfiguredProvider,
        message: 'App credential client_id is empty.',
        provider: token.provider,
        tokenId: token.id,
      );
    }

    return credential;
  }

  CloudSyncHttpException _mapRefreshError(
    DioException error, {
    required StackTrace stackTrace,
    required AuthTokenEntry token,
    required Uri tokenEndpoint,
  }) {
    final snippet = CloudSyncHttpException.buildResponseBodySnippet(
      error.response?.data,
    );

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.timeout,
          message: 'OAuth refresh request timed out.',
          provider: token.provider,
          tokenId: token.id,
          requestUri: tokenEndpoint,
          statusCode: error.response?.statusCode,
          responseBodySnippet: snippet,
          cause: error,
        );
      case DioExceptionType.cancel:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.cancelled,
          message: 'OAuth refresh request was cancelled.',
          provider: token.provider,
          tokenId: token.id,
          requestUri: tokenEndpoint,
          cause: error,
        );
      case DioExceptionType.badResponse:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.refreshFailed,
          message: 'OAuth refresh endpoint rejected the request.',
          provider: token.provider,
          tokenId: token.id,
          statusCode: error.response?.statusCode,
          requestUri: tokenEndpoint,
          responseBodySnippet: snippet,
          cause: error,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.network,
          message: 'OAuth refresh request failed due to a network error.',
          provider: token.provider,
          tokenId: token.id,
          statusCode: error.response?.statusCode,
          requestUri: tokenEndpoint,
          responseBodySnippet: snippet,
          cause: error,
        );
      case DioExceptionType.unknown:
        logError(
          'Unexpected OAuth refresh error: $error',
          error: error,
          stackTrace: stackTrace,
          tag: _logTag,
        );
        return CloudSyncHttpException(
          type: CloudSyncHttpExceptionType.unknown,
          message: 'Unexpected OAuth refresh error.',
          provider: token.provider,
          tokenId: token.id,
          statusCode: error.response?.statusCode,
          requestUri: tokenEndpoint,
          responseBodySnippet: snippet,
          cause: error,
        );
    }
  }

  String _requireAccessToken(
    Map<String, dynamic> payload,
    AuthTokenEntry token,
  ) {
    final accessToken = _normalizeString(payload['access_token']);
    if (accessToken != null) {
      return accessToken;
    }

    throw CloudSyncHttpException(
      type: CloudSyncHttpExceptionType.refreshFailed,
      message: 'Refresh response did not contain access_token.',
      provider: token.provider,
      tokenId: token.id,
      responseBodySnippet: CloudSyncHttpException.buildResponseBodySnippet(
        payload,
      ),
    );
  }

  DateTime? _resolveExpiresAt(Object? rawValue) {
    if (rawValue is int) {
      return DateTime.now().add(Duration(seconds: rawValue));
    }
    if (rawValue is String) {
      final seconds = int.tryParse(rawValue.trim());
      if (seconds != null) {
        return DateTime.now().add(Duration(seconds: seconds));
      }
    }
    return null;
  }

  List<String> _extractScopes(Object? rawScope) {
    if (rawScope is String) {
      return rawScope
          .split(RegExp(r'\s+'))
          .map((scope) => scope.trim())
          .where((scope) => scope.isNotEmpty)
          .toList(growable: false);
    }

    if (rawScope is List) {
      return rawScope
          .whereType<String>()
          .map((scope) => scope.trim())
          .where((scope) => scope.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }

  Map<String, dynamic> _buildExtraData(
    Map<String, dynamic> payload, {
    required Map<String, dynamic> previous,
  }) {
    final extraData = <String, dynamic>{...previous};
    extraData.addAll(payload);
    extraData.remove('access_token');
    extraData.remove('refresh_token');
    extraData.remove('token_type');
    extraData.remove('expires_in');
    extraData.remove('scope');
    return extraData;
  }

  String? _normalizeString(Object? value) {
    if (value is! String) {
      return null;
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
