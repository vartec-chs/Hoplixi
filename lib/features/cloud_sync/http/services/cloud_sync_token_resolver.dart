import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/services/auth_tokens_service.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';

class CloudSyncTokenResolver {
  const CloudSyncTokenResolver(this._authTokensService);

  final AuthTokensService _authTokensService;

  Future<AuthTokenEntry> requireToken(String tokenId) async {
    await _authTokensService.initialize();

    final token = await _authTokensService.getTokenById(tokenId);
    if (token == null) {
      throw CloudSyncHttpException(
        type: CloudSyncHttpExceptionType.tokenNotFound,
        message: 'OAuth token was not found.',
        tokenId: tokenId,
      );
    }

    return token;
  }

  Future<AuthTokenEntry> saveToken(AuthTokenEntry token) async {
    await _authTokensService.initialize();
    return _authTokensService.upsertToken(token);
  }
}
