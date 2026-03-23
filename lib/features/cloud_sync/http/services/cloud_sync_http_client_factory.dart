import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_http_client.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_refresh_service.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_resolver.dart';

class CloudSyncHttpClientFactory {
  const CloudSyncHttpClientFactory({
    required CloudSyncTokenResolver tokenResolver,
    required CloudSyncTokenRefreshService tokenRefreshService,
  }) : _tokenResolver = tokenResolver,
       _tokenRefreshService = tokenRefreshService;

  final CloudSyncTokenResolver _tokenResolver;
  final CloudSyncTokenRefreshService _tokenRefreshService;

  Future<CloudSyncHttpClient> clientForToken(String tokenId) async {
    final token = await _tokenResolver.requireToken(tokenId);
    return CloudSyncHttpClient(
      tokenId: tokenId,
      provider: token.provider,
      tokenResolver: _tokenResolver,
      tokenRefreshService: _tokenRefreshService,
    );
  }
}
