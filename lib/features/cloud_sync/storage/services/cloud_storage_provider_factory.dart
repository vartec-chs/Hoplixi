import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_http_client_factory.dart';
import 'package:hoplixi/features/cloud_sync/http/services/cloud_sync_token_resolver.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/cloud_sync/storage/providers_impl/yandex_drive/yandex_drive_cloud_storage_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider.dart';

class CloudStorageProviderFactory {
  const CloudStorageProviderFactory({
    required CloudSyncTokenResolver tokenResolver,
    required CloudSyncHttpClientFactory httpClientFactory,
  }) : _tokenResolver = tokenResolver,
       _httpClientFactory = httpClientFactory;

  final CloudSyncTokenResolver _tokenResolver;
  final CloudSyncHttpClientFactory _httpClientFactory;

  Future<CloudStorageProvider> providerForToken(String tokenId) async {
    final token = await _tokenResolver.requireToken(tokenId);
    final httpClient = await _httpClientFactory.clientForToken(tokenId);

    switch (token.provider) {
      case CloudSyncProvider.yandex:
        return YandexDriveCloudStorageProvider(
          tokenId: tokenId,
          httpClient: httpClient,
        );
      case CloudSyncProvider.dropbox:
      case CloudSyncProvider.google:
      case CloudSyncProvider.onedrive:
      case CloudSyncProvider.other:
        throw CloudStorageException(
          type: CloudStorageExceptionType.unsupportedOperation,
          message:
              'Cloud storage provider ${token.provider.id} is not implemented yet.',
          provider: token.provider,
        );
    }
  }
}
