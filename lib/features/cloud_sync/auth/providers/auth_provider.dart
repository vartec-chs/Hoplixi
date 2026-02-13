import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoplixi/features/cloud_sync/auth/providers/token_service_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/auth_providers_service.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/providers/oauth_apps_service_provider.dart';

final authProviderServiceProvider = Provider<AuthProvidersService>((ref) {
  final appsService = ref.watch(oauthAppsServiceProvider);
  final tokenService = ref.watch(tokenServiceProvider);

  final service = AuthProvidersService(
    appsService: appsService,
    tokenService: tokenService,
  );

  return service;
});

/// AsyncNotifier для управления инициализацией AuthProvidersService
class AuthProvidersServiceNotifier extends AsyncNotifier<AuthProvidersService> {
  @override
  Future<AuthProvidersService> build() async {
    final service = ref.watch(authProviderServiceProvider);
    final result = await service.initialize();

    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }

    return service;
  }
}

/// AsyncNotifierProvider для AuthProvidersService с состоянием инициализации
final authProvidersServiceAsyncProvider =
    AsyncNotifierProvider<AuthProvidersServiceNotifier, AuthProvidersService>(
      AuthProvidersServiceNotifier.new,
    );
