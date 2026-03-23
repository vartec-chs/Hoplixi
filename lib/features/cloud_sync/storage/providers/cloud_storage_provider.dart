import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/http/providers/cloud_sync_http_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_provider_factory.dart';
import 'package:hoplixi/features/cloud_sync/storage/services/cloud_storage_repository.dart';

final cloudStorageProviderFactoryProvider =
    Provider<CloudStorageProviderFactory>((ref) {
      final tokenResolver = ref.watch(cloudSyncTokenResolverProvider);
      final httpClientFactory = ref.watch(cloudSyncHttpClientFactoryProvider);
      return CloudStorageProviderFactory(
        tokenResolver: tokenResolver,
        httpClientFactory: httpClientFactory,
      );
    });

final cloudStorageRepositoryProvider = Provider<CloudStorageRepository>((ref) {
  final providerFactory = ref.watch(cloudStorageProviderFactoryProvider);
  return CloudStorageRepository(providerFactory);
});
