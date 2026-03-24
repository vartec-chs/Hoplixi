import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_success_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_method.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_oauth_result.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_appauth_mobile_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_desktop_loopback_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_google_sign_in_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_oauth_http_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/cloud_sync_auth_user_info.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/services/auth_tokens_service.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:uuid/uuid.dart';

class CloudSyncAuthService {
  CloudSyncAuthService(this._hiveBoxManager)
    : _oauthHttpService = const CloudSyncOAuthHttpService(),
      _uuid = const Uuid() {
    _appAuthMobileService = CloudSyncAppAuthMobileService(_oauthHttpService);
    _desktopLoopbackService = CloudSyncDesktopLoopbackService(
      _oauthHttpService,
    );
    _googleSignInService = CloudSyncGoogleSignInService();
    _authTokensService = AuthTokensService(_hiveBoxManager);
  }

  static const String _logTag = 'CloudSyncAuthService';

  final HiveBoxManager _hiveBoxManager;
  final CloudSyncOAuthHttpService _oauthHttpService;
  final Uuid _uuid;
  late final CloudSyncAppAuthMobileService _appAuthMobileService;
  late final CloudSyncDesktopLoopbackService _desktopLoopbackService;
  late final CloudSyncGoogleSignInService _googleSignInService;
  late final AuthTokensService _authTokensService;

  String? _activeOperationId;
  bool _cancelRequested = false;

  Future<AuthFlowSuccessResult> authorize({
    required AppCredentialEntry credential,
    CloudSyncAuthMethod method = CloudSyncAuthMethod.automatic,
    String? manualAuthorizationCode,
  }) async {
    await _authTokensService.initialize();

    final operationId = _uuid.v4();
    _activeOperationId = operationId;
    _cancelRequested = false;

    try {
      final oauthResult = await _runStrategy(
        credential,
        method: method,
        manualAuthorizationCode: manualAuthorizationCode,
      );
      _throwIfCancelled(operationId);

      final savedToken = await _saveToken(
        credential: credential,
        oauthResult: oauthResult,
      );

      logInfo(
        'Cloud sync auth success for ${credential.provider.id} using ${credential.id}',
        tag: _logTag,
      );

      return AuthFlowSuccessResult(
        savedTokenId: savedToken.id,
        savedToken: savedToken,
      );
    } catch (error, stackTrace) {
      logError(
        'Cloud sync auth failed: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    } finally {
      if (_activeOperationId == operationId) {
        _activeOperationId = null;
        _cancelRequested = false;
      }
    }
  }

  CloudSyncAuthError mapError(Object error) {
    if (_cancelRequested) {
      return const CloudSyncAuthError.cancelled(
        message: 'Authorization was cancelled by the user.',
      );
    }

    if (error is CloudSyncAuthException) {
      return error.error;
    }

    return CloudSyncAuthError.unknown(message: error.toString());
  }

  Future<void> cancelActiveFlow() async {
    _cancelRequested = true;
    await _desktopLoopbackService.cancelActiveFlow();
  }

  Future<void> dispose() async {
    await _desktopLoopbackService.cancelActiveFlow();
    await _authTokensService.dispose();
  }

  Future<void> launchManualCodeAuthorization({
    required AppCredentialEntry credential,
  }) async {
    _ensureManualCodeAuthSupported(credential);

    await _desktopLoopbackService.launchManualAuthorization(
      credential: credential,
    );
  }

  Uri buildManualCodeAuthorizationUri({
    required AppCredentialEntry credential,
  }) {
    _ensureManualCodeAuthSupported(credential);

    return _desktopLoopbackService.buildManualAuthorizationUri(
      credential: credential,
    );
  }

  Future<CloudSyncOAuthResult> _runStrategy(
    AppCredentialEntry credential, {
    CloudSyncAuthMethod method = CloudSyncAuthMethod.automatic,
    String? manualAuthorizationCode,
  }) {
    if (method == CloudSyncAuthMethod.manualCode) {
      _ensureManualCodeAuthSupported(credential);
      return _authorizeWithManualCode(
        credential: credential,
        manualAuthorizationCode: manualAuthorizationCode,
      );
    }

    if (UniversalPlatform.isDesktop) {
      return _desktopLoopbackService.authorize(
        credential: credential,
        method: method,
        manualAuthorizationCode: manualAuthorizationCode,
      );
    }

    if (credential.provider == CloudSyncProvider.google) {
      return _googleSignInService.authorize(credential: credential);
    }

    return _appAuthMobileService.authorize(credential: credential);
  }

  Future<CloudSyncOAuthResult> _authorizeWithManualCode({
    required AppCredentialEntry credential,
    String? manualAuthorizationCode,
  }) async {
    final code = manualAuthorizationCode?.trim();
    if (code == null || code.isEmpty) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message: 'Authorization code is required for manual OAuth flow.',
        ),
      );
    }

    final tokenResult = await _oauthHttpService.exchangeAuthorizationCode(
      credential: credential,
      code: code,
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
        'manual_code_entry': true,
        'raw_user_info': ?userInfo,
      },
    );
  }

  void _ensureManualCodeAuthSupported(AppCredentialEntry credential) {
    if (!credential.provider.metadata.supportsManualCodeAuth) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.unsupportedCredential(
          message:
              'Manual code authorization is not supported for this provider.',
        ),
      );
    }
  }

  Future<AuthTokenEntry> _saveToken({
    required AppCredentialEntry credential,
    required CloudSyncOAuthResult oauthResult,
  }) {
    final token = AuthTokenEntry(
      id: _uuid.v4(),
      provider: credential.provider,
      accessToken: oauthResult.accessToken,
      refreshToken: oauthResult.refreshToken,
      tokenType: oauthResult.tokenType,
      expiresAt: oauthResult.expiresAt,
      scopes: oauthResult.scopes,
      appCredentialId: credential.id,
      appCredentialName: credential.name,
      accountId: oauthResult.accountId,
      accountEmail: oauthResult.accountEmail,
      accountName: oauthResult.accountName,
      extraData: oauthResult.extraData,
    );

    return _authTokensService.upsertToken(token);
  }

  void _throwIfCancelled(String operationId) {
    if (_cancelRequested || _activeOperationId != operationId) {
      throw const CloudSyncAuthException(
        CloudSyncAuthError.cancelled(
          message: 'Authorization was cancelled by the user.',
        ),
      );
    }
  }
}
