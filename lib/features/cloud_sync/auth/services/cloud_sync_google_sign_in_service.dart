import 'dart:async';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_oauth_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class CloudSyncGoogleSignInService {
  CloudSyncGoogleSignInService() : _googleSignIn = GoogleSignIn.instance;

  static const String _logTag = 'CloudSyncGoogleSignInService';

  final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSubscription;
  String? _initializedClientId;
  String? _initializedServerClientId;
  bool _isInitialized = false;

  Future<CloudSyncOAuthResult> authorize({
    required AppCredentialEntry credential,
  }) async {
    final metadata = credential.provider.metadata;
    final clientId = credential.clientId.trim();
    final serverClientId = credential.clientSecret?.trim();
    if (clientId.isEmpty) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message: 'Google credential client ID is missing.',
        ),
      );
    }

    logInfo(
      'Starting Google Sign-In authorization.',
      tag: _logTag,
      data: <String, dynamic>{
        'provider': credential.provider.id,
        'credentialId': credential.id,
        'clientIdHint': _buildClientIdHint(clientId),
        'hasServerClientId':
            serverClientId != null && serverClientId.isNotEmpty,
        'scopeCount': metadata.scopes.length,
        'supportsAuthenticate': _googleSignIn.supportsAuthenticate(),
        'authorizationRequiresUserInteraction': _googleSignIn
            .authorizationRequiresUserInteraction(),
      },
    );

    await _ensureInitialized(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.unsupportedCredential(
            message:
                'Google Sign-In authenticate() is not supported on this platform.',
          ),
        );
      }

      logInfo(
        'Calling GoogleSignIn.authenticate().',
        tag: _logTag,
        data: <String, dynamic>{
          'credentialId': credential.id,
          'scopes': metadata.scopes,
        },
      );
      final account = await _googleSignIn.authenticate(
        scopeHint: metadata.scopes,
      );

      logInfo(
        'Google account authenticated. Requesting authorization.',
        tag: _logTag,
        data: <String, dynamic>{
          'credentialId': credential.id,
          'accountId': account.id,
          'accountEmail': account.email,
        },
      );

      var authorization = await account.authorizationClient
          .authorizationForScopes(metadata.scopes);
      authorization ??= await account.authorizationClient.authorizeScopes(
        metadata.scopes,
      );

      GoogleSignInServerAuthorization? serverAuthorization;
      if (serverClientId != null && serverClientId.isNotEmpty) {
        try {
          logInfo(
            'Requesting Google server authorization code.',
            tag: _logTag,
            data: <String, dynamic>{
              'credentialId': credential.id,
              'accountId': account.id,
            },
          );
          serverAuthorization = await account.authorizationClient
              .authorizeServer(metadata.scopes);
          logInfo(
            'Google server authorization request finished.',
            tag: _logTag,
            data: <String, dynamic>{
              'credentialId': credential.id,
              'accountId': account.id,
              'hasServerAuthCode': serverAuthorization != null,
            },
          );
        } on GoogleSignInException catch (error) {
          final serverDiagnostic = _buildGoogleExceptionDiagnostic(error);
          logWarning(
            'Google server authorization request failed: $serverDiagnostic',
            tag: _logTag,
            data: <String, dynamic>{
              'provider': credential.provider.id,
              'credentialId': credential.id,
            },
          );
        }
      }

      logInfo(
        'Google Sign-In authorization succeeded.',
        tag: _logTag,
        data: <String, dynamic>{
          'credentialId': credential.id,
          'accountId': account.id,
          'accountEmail': account.email,
          'hasAccessToken': authorization.accessToken.isNotEmpty,
          'hasIdToken': account.authentication.idToken != null,
          'hasServerAuthCode': serverAuthorization != null,
        },
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
          if (account.authentication.idToken != null)
            'google_id_token': account.authentication.idToken,
          if (serverAuthorization != null)
            'google_server_auth_code': serverAuthorization.serverAuthCode,
        },
      );
    } on GoogleSignInException catch (error) {
      final diagnostic = _buildGoogleExceptionDiagnostic(error);
      logWarning(
        'Google Sign-In failed: $diagnostic',
        tag: _logTag,
        data: <String, dynamic>{
          'provider': credential.provider.id,
          'credentialId': credential.id,
        },
      );
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw CloudSyncAuthException(
            CloudSyncAuthError.cancelled(message: diagnostic),
          );
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw CloudSyncAuthException(
            CloudSyncAuthError.unsupportedCredential(message: diagnostic),
          );
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
        case GoogleSignInExceptionCode.userMismatch:
        case GoogleSignInExceptionCode.unknownError:
          throw CloudSyncAuthException(
            CloudSyncAuthError.oauthProvider(message: diagnostic),
          );
      }
    }
  }

  Future<void> _ensureInitialized({
    required String clientId,
    String? serverClientId,
  }) async {
    final normalizedServerClientId =
        serverClientId == null || serverClientId.isEmpty
        ? null
        : serverClientId;

    if (_isInitialized) {
      if (_initializedClientId != clientId ||
          _initializedServerClientId != normalizedServerClientId) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.unsupportedCredential(
            message:
                'Google Sign-In is already initialized with another client configuration in this app session.',
          ),
        );
      }
      return;
    }

    logInfo(
      'Initializing Google Sign-In client.',
      tag: _logTag,
      data: <String, dynamic>{
        'clientIdHint': _buildClientIdHint(clientId),
        'hasServerClientId': normalizedServerClientId != null,
      },
    );

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: normalizedServerClientId,
    );
    _authEventsSubscription ??= _googleSignIn.authenticationEvents.listen(
      (event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            logInfo(
              'Google authentication event sign-in received.',
              tag: _logTag,
              data: <String, dynamic>{
                'accountId': event.user.id,
                'accountEmail': event.user.email,
              },
            );
          case GoogleSignInAuthenticationEventSignOut():
            logInfo(
              'Google authentication event sign-out received.',
              tag: _logTag,
            );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        logError(
          'Google authentication event stream failed: $error',
          stackTrace: stackTrace,
          tag: _logTag,
        );
      },
    );
    _isInitialized = true;
    _initializedClientId = clientId;
    _initializedServerClientId = normalizedServerClientId;

    logInfo(
      'Google Sign-In client initialized.',
      tag: _logTag,
      data: <String, dynamic>{
        'clientIdHint': _buildClientIdHint(clientId),
        'hasServerClientId': normalizedServerClientId != null,
      },
    );
  }

  String _buildGoogleExceptionDiagnostic(GoogleSignInException error) {
    final parts = <String>[
      'Google Sign-In failed',
      'code=${error.code.name}',
      if (error.description case final description?) 'description=$description',
      'details=${error.toString()}',
    ];
    return parts.join(' | ');
  }

  String _buildClientIdHint(String clientId) {
    if (clientId.length <= 12) {
      return clientId;
    }
    return '${clientId.substring(0, 6)}...${clientId.substring(clientId.length - 6)}';
  }
}
