import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoplixi/features/old/cloud_sync/auth/providers/token_service_provider.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/services/auth_providers_service.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/providers/oauth_apps_service_provider.dart';

final providerServiceProvider = Provider<AuthProvidersService>((ref) {
  final appsService = ref.watch(oauthAppsServiceProvider);
  final tokenService = ref.watch(tokenServiceProvider);

  final service = AuthProvidersService(
    appsService: appsService,
    tokenService: tokenService,
  );

  return service;
});
