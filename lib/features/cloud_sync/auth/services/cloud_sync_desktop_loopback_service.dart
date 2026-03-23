import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_oauth_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_oauth_http_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/cloud_sync_auth_user_info.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/desktop_browser_launcher.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/oauth_pkce.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class CloudSyncDesktopLoopbackService {
  CloudSyncDesktopLoopbackService(this._oauthHttpService);

  static const Duration _authorizationTimeout = Duration(minutes: 5);
  static const String _logTag = 'CloudSyncDesktopLoopbackService';

  final CloudSyncOAuthHttpService _oauthHttpService;
  _DesktopAuthSession? _activeSession;

  Future<CloudSyncOAuthResult> authorize({
    required AppCredentialEntry credential,
  }) async {
    await cancelActiveFlow();

    final metadata = credential.provider.metadata;
    final authorizationEndpoint = metadata.authorizationEndpoint;
    final redirectUri = Uri.parse(metadata.desktopRedirectUri);
    if (authorizationEndpoint == null || metadata.tokenEndpoint == null) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message: 'OAuth endpoints are missing for this provider.',
        ),
      );
    }

    final pkce = OAuthPkcePair.generate();
    final server = await _bindLoopbackServer(redirectUri);
    final session = _DesktopAuthSession(server: server);
    _activeSession = session;

    server.listen(
      (request) => _handleRequest(
        request: request,
        session: session,
        expectedState: pkce.state,
      ),
      onError: (Object error) {
        if (!session.callbackCompleter.isCompleted) {
          session.callbackCompleter.completeError(error);
        }
      },
      cancelOnError: false,
    );

    final authorizationUri = _buildAuthorizationUri(
      authorizationEndpoint: Uri.parse(authorizationEndpoint),
      credential: credential,
      redirectUri: metadata.desktopRedirectUri,
      codeChallenge: pkce.codeChallenge,
      state: pkce.state,
    );

    try {
      await launchDesktopBrowser(authorizationUri);
      final callback = await Future.any<_DesktopAuthCallback>([
        session.callbackCompleter.future,
        session.cancelCompleter.future.then(
          (_) => throw const CloudSyncAuthException(
            CloudSyncAuthError.cancelled(
              message: 'Authorization was cancelled by the user.',
            ),
          ),
        ),
        Future<_DesktopAuthCallback>.delayed(
          _authorizationTimeout,
          () => throw const CloudSyncAuthException(
            CloudSyncAuthError.timeout(
              message: 'The desktop authorization timed out.',
            ),
          ),
        ),
      ]);

      if (callback.error != null) {
        if (callback.error == 'access_denied') {
          throw const CloudSyncAuthException(
            CloudSyncAuthError.cancelled(
              message: 'Authorization was cancelled by the user.',
            ),
          );
        }

        throw CloudSyncAuthException(
          CloudSyncAuthError.oauthProvider(
            message: callback.errorDescription ?? callback.error,
          ),
        );
      }

      if (callback.code == null || callback.code!.trim().isEmpty) {
        throw const CloudSyncAuthException(
          CloudSyncAuthError.oauthProvider(
            message: 'Authorization callback does not contain a code.',
          ),
        );
      }

      final tokenResult = await _oauthHttpService.exchangeAuthorizationCode(
        credential: credential,
        redirectUri: metadata.desktopRedirectUri,
        code: callback.code!.trim(),
        codeVerifier: pkce.codeVerifier,
      );
      final userInfo = await _oauthHttpService.fetchUserInfo(
        credential: credential,
        accessToken: tokenResult.accessToken,
      );

      return tokenResult.copyWith(
        accountId: tokenResult.accountId ?? extractAccountId(userInfo),
        accountEmail: tokenResult.accountEmail ?? extractAccountEmail(userInfo),
        accountName: tokenResult.accountName ?? extractAccountName(userInfo),
        extraData: <String, dynamic>{
          ...tokenResult.extraData,
          if (userInfo != null) 'raw_user_info': userInfo,
        },
      );
    } finally {
      await _disposeSession(session);
      if (identical(_activeSession, session)) {
        _activeSession = null;
      }
    }
  }

  Future<void> cancelActiveFlow() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    if (!session.cancelCompleter.isCompleted) {
      session.cancelCompleter.complete();
    }
    await _disposeSession(session);
    if (identical(_activeSession, session)) {
      _activeSession = null;
    }
  }

  Future<HttpServer> _bindLoopbackServer(Uri redirectUri) async {
    try {
      return await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        redirectUri.port,
      );
    } on SocketException catch (error, stackTrace) {
      logError(
        'Failed to bind loopback server: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      throw CloudSyncAuthException(
        CloudSyncAuthError.network(
          message: 'Failed to start loopback server on ${redirectUri.port}.',
        ),
      );
    }
  }

  Uri _buildAuthorizationUri({
    required Uri authorizationEndpoint,
    required AppCredentialEntry credential,
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) {
    final metadata = credential.provider.metadata;
    final query = <String, String>{
      'client_id': credential.clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': metadata.scopes.join(' '),
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      ...metadata.additionalAuthParameters,
    };

    return authorizationEndpoint.replace(
      queryParameters: <String, String>{
        ...authorizationEndpoint.queryParameters,
        ...query,
      },
    );
  }

  Future<void> _handleRequest({
    required HttpRequest request,
    required _DesktopAuthSession session,
    required String expectedState,
  }) async {
    if (request.uri.path != '/callback') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final state = request.uri.queryParameters['state'];
    final code = request.uri.queryParameters['code'];
    final error = request.uri.queryParameters['error'];
    final errorDescription = request.uri.queryParameters['error_description'];

    if (state != expectedState) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Invalid OAuth state.');
      await request.response.close();

      if (!session.callbackCompleter.isCompleted) {
        session.callbackCompleter.completeError(
          const CloudSyncAuthException(
            CloudSyncAuthError.oauthProvider(
              message: 'OAuth callback state mismatch.',
            ),
          ),
        );
      }
      return;
    }

    request.response.headers.contentType = ContentType.html;
    request.response.write(_buildSuccessHtml(error: error));
    await request.response.close();

    if (!session.callbackCompleter.isCompleted) {
      session.callbackCompleter.complete(
        _DesktopAuthCallback(
          code: code,
          error: error,
          errorDescription: errorDescription,
        ),
      );
    }
  }

  String _buildSuccessHtml({String? error}) {
    final title = error == null
        ? 'Authorization completed'
        : 'Authorization failed';
    final description = error == null
        ? 'You can return to Hoplixi and close this browser tab.'
        : 'Return to Hoplixi to see the error details.';

    return jsonEncode(<String, String>{
          'title': title,
          'description': description,
        })
        .replaceAll(
          '{',
          '<html><body style="font-family:sans-serif;padding:24px;">',
        )
        .replaceAll('}', '</body></html>')
        .replaceAll('"title":"', '<h2>')
        .replaceAll('","description":"', '</h2><p>')
        .replaceAll('"', '');
  }

  Future<void> _disposeSession(_DesktopAuthSession session) async {
    try {
      await session.server.close(force: true);
    } catch (_) {
      // no-op
    }
  }
}

class _DesktopAuthSession {
  _DesktopAuthSession({required this.server});

  final HttpServer server;
  final Completer<_DesktopAuthCallback> callbackCompleter =
      Completer<_DesktopAuthCallback>();
  final Completer<void> cancelCompleter = Completer<void>();
}

class _DesktopAuthCallback {
  const _DesktopAuthCallback({this.code, this.error, this.errorDescription});

  final String? code;
  final String? error;
  final String? errorDescription;
}
