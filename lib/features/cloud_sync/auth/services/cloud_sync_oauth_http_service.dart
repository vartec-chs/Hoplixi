import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_oauth_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class CloudSyncOAuthHttpService {
  const CloudSyncOAuthHttpService();

  Future<CloudSyncOAuthResult> exchangeAuthorizationCode({
    required AppCredentialEntry credential,
    required String redirectUri,
    required String code,
    required String codeVerifier,
  }) async {
    final metadata = credential.provider.metadata;
    final tokenEndpoint = metadata.tokenEndpoint;
    if (tokenEndpoint == null) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message: 'OAuth token endpoint is missing for this provider.',
        ),
      );
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(tokenEndpoint));
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );

      final body = <String, String>{
        'grant_type': 'authorization_code',
        'client_id': credential.clientId,
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      };
      if (credential.clientSecret != null &&
          credential.clientSecret!.trim().isNotEmpty) {
        body['client_secret'] = credential.clientSecret!.trim();
      }

      request.write(Uri(queryParameters: body).query);
      final response = await request.close();
      final rawBody = await utf8.decoder.bind(response).join();
      final json = _decodeJsonMap(rawBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CloudSyncAuthException(
          CloudSyncAuthError.oauthProvider(
            message:
                _extractProviderMessage(json) ??
                'Token endpoint returned ${response.statusCode}.',
          ),
        );
      }

      return CloudSyncOAuthResult(
        accessToken: (json['access_token'] as String?)?.trim() ?? '',
        refreshToken: (json['refresh_token'] as String?)?.trim(),
        tokenType: (json['token_type'] as String?)?.trim(),
        expiresAt: _resolveExpiresAt(json['expires_in']),
        scopes: _extractScopes(json['scope']),
        extraData: _buildTokenExtraData(json),
      );
    } on SocketException catch (error) {
      throw CloudSyncAuthException(
        CloudSyncAuthError.network(message: error.message),
      );
    } on HandshakeException catch (error) {
      throw CloudSyncAuthException(
        CloudSyncAuthError.network(message: error.message),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>?> fetchUserInfo({
    required AppCredentialEntry credential,
    required String accessToken,
  }) async {
    final metadata = credential.provider.metadata;
    final userInfoEndpoint = metadata.userInfoEndpoint;
    if (userInfoEndpoint == null || accessToken.trim().isEmpty) {
      return null;
    }

    final client = HttpClient();
    try {
      final request = metadata.userInfoMethod.name == 'post'
          ? await client.postUrl(Uri.parse(userInfoEndpoint))
          : await client.getUrl(Uri.parse(userInfoEndpoint));
      request.headers.set(
        HttpHeaders.authorizationHeader,
        '${metadata.userInfoAuthScheme} ${accessToken.trim()}',
      );

      final response = await request.close();
      final rawBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CloudSyncAuthException(
          CloudSyncAuthError.oauthProvider(
            message: 'User info endpoint returned ${response.statusCode}.',
          ),
        );
      }

      return _decodeJsonMap(rawBody);
    } on SocketException catch (error) {
      throw CloudSyncAuthException(
        CloudSyncAuthError.network(message: error.message),
      );
    } on HandshakeException catch (error) {
      throw CloudSyncAuthException(
        CloudSyncAuthError.network(message: error.message),
      );
    } finally {
      client.close(force: true);
    }
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

  Map<String, dynamic> _buildTokenExtraData(Map<String, dynamic> json) {
    final extraData = Map<String, dynamic>.from(json);
    extraData.remove('access_token');
    extraData.remove('refresh_token');
    extraData.remove('token_type');
    extraData.remove('expires_in');
    extraData.remove('scope');
    return extraData;
  }

  Map<String, dynamic> _decodeJsonMap(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const CloudSyncAuthException(
      CloudSyncAuthError.oauthProvider(
        message: 'OAuth endpoint returned an unexpected payload.',
      ),
    );
  }

  String? _extractProviderMessage(Map<String, dynamic> json) {
    final direct = json['error_description'] ?? json['error'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    return null;
  }
}
