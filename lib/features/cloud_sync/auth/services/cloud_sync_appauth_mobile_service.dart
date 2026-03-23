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
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          credential.clientId,
          redirectUri,
          clientSecret: credential.clientSecret,
          scopes: metadata.scopes,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
          ),
          additionalParameters: metadata.additionalAuthParameters,
        ),
      );

      if (response == null || (response.accessToken?.trim().isEmpty ?? true)) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.cancelled(
            message: 'Authorization was cancelled by the user.',
          ),
        );
      }

      final userInfo = await _oauthHttpService.fetchUserInfo(
        credential: credential,
        accessToken: response.accessToken!,
      );
      final extraData = <String, dynamic>{
        if (response.idToken != null && response.idToken!.trim().isNotEmpty)
          'id_token': response.idToken,
        if (userInfo != null) 'raw_user_info': userInfo,
      };

      return CloudSyncOAuthResult(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        tokenType: response.tokenType,
        expiresAt: response.accessTokenExpirationDateTime,
        scopes: response.scopes ?? metadata.scopes,
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
    }
  }
}
