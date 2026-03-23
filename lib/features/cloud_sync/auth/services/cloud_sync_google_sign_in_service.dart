import 'package:google_sign_in/google_sign_in.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_oauth_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class CloudSyncGoogleSignInService {
  CloudSyncGoogleSignInService() : _googleSignIn = GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  String? _initializedClientId;
  bool _isInitialized = false;

  Future<CloudSyncOAuthResult> authorize({
    required AppCredentialEntry credential,
  }) async {
    final metadata = credential.provider.metadata;
    final clientId = credential.clientId.trim();
    if (clientId.isEmpty) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message: 'Google credential client ID is missing.',
        ),
      );
    }

    await _ensureInitialized(clientId);

    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: metadata.scopes,
      );

      var authorization = await account.authorizationClient
          .authorizationForScopes(metadata.scopes);
      authorization ??= await account.authorizationClient.authorizeScopes(
        metadata.scopes,
      );

      return CloudSyncOAuthResult(
        accessToken: authorization.accessToken,
        tokenType: 'Bearer',
        scopes: metadata.scopes,
        accountId: account.id,
        accountEmail: account.email,
        accountName: account.displayName,
        extraData: <String, dynamic>{
          if (account.photoUrl != null) 'photo_url': account.photoUrl,
        },
      );
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw const CloudSyncAuthException(
            CloudSyncAuthError.cancelled(
              message: 'Authorization was cancelled by the user.',
            ),
          );
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw CloudSyncAuthException(
            CloudSyncAuthError.unsupportedCredential(
              message: error.description ?? 'Google Sign-In is misconfigured.',
            ),
          );
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
        case GoogleSignInExceptionCode.userMismatch:
        case GoogleSignInExceptionCode.unknownError:
          throw CloudSyncAuthException(
            CloudSyncAuthError.oauthProvider(
              message: error.description ?? error.code.name,
            ),
          );
      }
    }
  }

  Future<void> _ensureInitialized(String clientId) async {
    if (_isInitialized) {
      if (_initializedClientId != clientId) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.unsupportedCredential(
            message:
                'Google Sign-In is already initialized with another client ID in this app session.',
          ),
        );
      }
      return;
    }

    await _googleSignIn.initialize(clientId: clientId);
    _isInitialized = true;
    _initializedClientId = clientId;
  }
}
