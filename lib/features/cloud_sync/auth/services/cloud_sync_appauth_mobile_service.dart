import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_oauth_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_oauth_http_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/cloud_sync_auth_credential_support.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/cloud_sync_auth_user_info.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class CloudSyncAppAuthMobileService {
  CloudSyncAppAuthMobileService(this._oauthHttpService)
    : _appAuth = const FlutterAppAuth();

  final FlutterAppAuth _appAuth;
  final CloudSyncOAuthHttpService _oauthHttpService;

  Future<CloudSyncOAuthResult> authorize({
    required AppCredentialEntry credential,
  }) async {
    final metadata = credential.provider.metadata;
    if (metadata.requiresManualCodeAuthOnMobile) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message:
              'Automatic mobile authorization is disabled for this provider. Use manual code authorization instead.',
        ),
      );
    }

    final redirectUri = resolveCredentialRedirectUri(credential);
    if (redirectUri == null) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message:
              'The selected credential is not supported on this mobile platform.',
        ),
      );
    }

    final authorizationEndpoint = metadata.authorizationEndpoint;
    final tokenEndpoint = metadata.tokenEndpoint;
    if (authorizationEndpoint == null || tokenEndpoint == null) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message: 'OAuth endpoints are missing for this provider.',
        ),
      );
    }

    try {
      final serviceConfiguration = AuthorizationServiceConfiguration(
        authorizationEndpoint: authorizationEndpoint,
        tokenEndpoint: tokenEndpoint,
      );

      final authorization = await _appAuth.authorize(
        AuthorizationRequest(
          credential.clientId,
          redirectUri,
          scopes: metadata.scopes,
          serviceConfiguration: serviceConfiguration,
          additionalParameters: metadata.additionalAuthParameters,
        ),
      );

      final authorizationCode = authorization.authorizationCode?.trim();
      if (authorizationCode == null || authorizationCode.isEmpty) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.cancelled(
            message: 'Authorization was cancelled by the user.',
          ),
        );
      }

      final tokenResponse = await _appAuth.token(
        TokenRequest(
          credential.clientId,
          redirectUri,
          clientSecret: credential.clientSecret,
          authorizationCode: authorizationCode,
          codeVerifier: authorization.codeVerifier,
          nonce: authorization.nonce,
          scopes: metadata.scopes,
          serviceConfiguration: serviceConfiguration,
        ),
      );

      final accessToken = tokenResponse.accessToken?.trim();
      if (accessToken == null || accessToken.isEmpty) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.oauthProvider(
            message: 'OAuth token exchange did not return access_token.',
          ),
        );
      }

      final userInfo = await _oauthHttpService.fetchUserInfo(
        credential: credential,
        accessToken: accessToken,
      );
      final extraData = <String, dynamic>{
        if (tokenResponse.idToken != null &&
            tokenResponse.idToken!.trim().isNotEmpty)
          'id_token': tokenResponse.idToken,
        if (authorization.authorizationAdditionalParameters != null)
          'authorization_additional_parameters':
              authorization.authorizationAdditionalParameters,
        if (tokenResponse.tokenAdditionalParameters != null)
          'token_additional_parameters':
              tokenResponse.tokenAdditionalParameters,
        if (userInfo != null) 'raw_user_info': userInfo,
      };

      return CloudSyncOAuthResult(
        accessToken: accessToken,
        refreshToken: tokenResponse.refreshToken,
        tokenType: tokenResponse.tokenType,
        expiresAt: tokenResponse.accessTokenExpirationDateTime,
        scopes: tokenResponse.scopes ?? metadata.scopes,
        accountId: extractAccountId(userInfo),
        accountEmail: extractAccountEmail(userInfo),
        accountName: extractAccountName(userInfo),
        extraData: extraData,
      );
    } on FlutterAppAuthUserCancelledException {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.cancelled(
          message: 'Authorization was cancelled by the user.',
        ),
      );
    } on FlutterAppAuthPlatformException catch (error) {
      throw CloudSyncAuthException(
        CloudSyncAuthError.oauthProvider(
          message:
              error.details.errorDescription ?? error.message ?? error.code,
        ),
      );
    } on PlatformException catch (error) {
      throw CloudSyncAuthException(
        CloudSyncAuthError.oauthProvider(
          message:
              error.message ??
              error.details?.toString() ??
              'Flutter AppAuth platform error: ${error.code}',
        ),
      );
    }
  }
}
