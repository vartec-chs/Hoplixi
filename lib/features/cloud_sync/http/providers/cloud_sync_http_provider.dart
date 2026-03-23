import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/providers/app_credentials_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_http_client_factory.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_refresh_service.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_resolver.dart';

final cloudSyncTokenResolverProvider = Provider<CloudSyncTokenResolver>((ref) {
  final authTokensService = ref.watch(authTokensServiceProvider);
  return CloudSyncTokenResolver(authTokensService);
});

final cloudSyncTokenRefreshServiceProvider =
    Provider<CloudSyncTokenRefreshService>((ref) {
      final tokenResolver = ref.watch(cloudSyncTokenResolverProvider);
      final appCredentialsService = ref.watch(appCredentialsServiceProvider);
      return CloudSyncTokenRefreshService(
        tokenResolver: tokenResolver,
        appCredentialsService: appCredentialsService,
      );
    });

final cloudSyncHttpClientFactoryProvider = Provider<CloudSyncHttpClientFactory>(
  (ref) {
    final tokenResolver = ref.watch(cloudSyncTokenResolverProvider);
    final tokenRefreshService = ref.watch(cloudSyncTokenRefreshServiceProvider);
    return CloudSyncHttpClientFactory(
      tokenResolver: tokenResolver,
      tokenRefreshService: tokenRefreshService,
    );
  },
);
