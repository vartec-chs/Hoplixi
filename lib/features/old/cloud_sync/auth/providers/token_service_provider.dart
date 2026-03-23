import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/services/token_service.dart';

final tokenServiceProvider = Provider<TokenService>((ref) {
  final hiveManager = getIt<HiveBoxManager>();
  final service = TokenService(hiveManager);

  // Автоматическая очистка при удалении провайдера
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
