import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/services/oauth_apps_service.dart';

final oauthAppsServiceProvider = Provider<OAuthAppsService>((ref) {
  final hiveManager = getIt<HiveBoxManager>();
  final service = OAuthAppsService(hiveManager);

  // Автоматическая очистка при удалении провайдера
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
