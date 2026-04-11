import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_tokens_import_result.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/services/auth_tokens_service.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

/// Провайдер сервиса auth tokens.
final authTokensServiceProvider = Provider<AuthTokensService>((ref) {
  final service = AuthTokensService(getIt<HiveBoxManager>());
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Основной список OAuth токенов.
final authTokensProvider =
    AsyncNotifierProvider<AuthTokensNotifier, List<AuthTokenEntry>>(
      AuthTokensNotifier.new,
    );

/// Токены, сгруппированные по провайдеру.
final authTokensByProviderProvider =
    Provider<Map<CloudSyncProvider, List<AuthTokenEntry>>>((ref) {
      final tokens = ref.watch(authTokensProvider).value ?? const [];
      final grouped = <CloudSyncProvider, List<AuthTokenEntry>>{};

      for (final provider in CloudSyncProvider.values) {
        grouped[provider] = tokens
            .where((token) => token.provider == provider)
            .toList(growable: false);
      }

      return grouped;
    });

/// Notifier списка OAuth токенов.
class AuthTokensNotifier extends AsyncNotifier<List<AuthTokenEntry>> {
  static const String _logTag = 'AuthTokensNotifier';

  @override
  Future<List<AuthTokenEntry>> build() async {
    final service = ref.read(authTokensServiceProvider);
    await service.initialize();
    return service.getAllTokens();
  }

  /// Перезагружает список токенов.
  Future<void> reload() async {
    final service = ref.read(authTokensServiceProvider);
    await service.initialize();
    state = const AsyncLoading();
    state = await AsyncValue.guard(service.getAllTokens);
  }

  /// Ищет токен по идентификатору.
  Future<AuthTokenEntry?> getTokenById(String id) async {
    final service = ref.read(authTokensServiceProvider);
    await service.initialize();
    return service.getTokenById(id);
  }

  /// Возвращает токены выбранного провайдера.
  Future<List<AuthTokenEntry>> getTokensByProvider(
    CloudSyncProvider provider,
  ) async {
    final service = ref.read(authTokensServiceProvider);
    await service.initialize();
    return service.getTokensByProvider(provider);
  }

  /// Сохраняет токен и обновляет список.
  Future<AuthTokenEntry> saveToken(AuthTokenEntry token) async {
    final service = ref.read(authTokensServiceProvider);
    try {
      await service.initialize();
      final saved = await service.upsertToken(token);
      state = AsyncData(await service.getAllTokens());
      return saved;
    } catch (error, stackTrace) {
      logError(
        'Failed to save auth token: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Удаляет токен и обновляет список.
  Future<void> deleteToken(String id) async {
    final service = ref.read(authTokensServiceProvider);
    try {
      await service.initialize();
      await service.deleteToken(id);
      state = AsyncData(await service.getAllTokens());
    } catch (error, stackTrace) {
      logError(
        'Failed to delete auth token: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Импортирует несколько токенов и обновляет состояние один раз.
  Future<AuthTokensImportResult> importTokens(
    List<AuthTokenEntry> tokens,
  ) async {
    final service = ref.read(authTokensServiceProvider);
    try {
      await service.initialize();
      final result = await service.importTokens(tokens);
      state = AsyncData(await service.getAllTokens());
      return result;
    } catch (error, stackTrace) {
      logError(
        'Failed to import auth tokens: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }
}
