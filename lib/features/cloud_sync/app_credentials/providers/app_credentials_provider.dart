import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/services/app_credentials_service.dart';

/// Провайдер сервиса app credentials.
final appCredentialsServiceProvider = Provider<AppCredentialsService>((ref) {
  final service = AppCredentialsService(getIt<HiveBoxManager>());
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Основной список всех app credentials.
final appCredentialsProvider =
    AsyncNotifierProvider<AppCredentialsNotifier, List<AppCredentialEntry>>(
      AppCredentialsNotifier.new,
    );

/// Только встроенные credentials.
final builtinAppCredentialsProvider = Provider<List<AppCredentialEntry>>((ref) {
  final allEntries = ref.watch(appCredentialsProvider).value ?? const [];
  return allEntries.where((entry) => entry.isBuiltin).toList(growable: false);
});

/// Только пользовательские credentials.
final userAppCredentialsProvider = Provider<List<AppCredentialEntry>>((ref) {
  final allEntries = ref.watch(appCredentialsProvider).value ?? const [];
  return allEntries.where((entry) => !entry.isBuiltin).toList(growable: false);
});

/// Notifier списка app credentials.
class AppCredentialsNotifier extends AsyncNotifier<List<AppCredentialEntry>> {
  static const String _logTag = 'AppCredentialsNotifier';

  @override
  Future<List<AppCredentialEntry>> build() async {
    final service = ref.read(appCredentialsServiceProvider);
    await service.initialize();
    return service.getAll();
  }

  /// Перезагружает список.
  Future<void> reload() async {
    final service = ref.read(appCredentialsServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(service.getAll);
  }

  /// Ищет запись по идентификатору.
  Future<AppCredentialEntry?> getById(String id) async {
    final service = ref.read(appCredentialsServiceProvider);
    return service.getById(id);
  }

  /// Сохраняет пользовательскую запись и обновляет список.
  Future<AppCredentialEntry> saveUserEntry(AppCredentialEntry entry) async {
    final service = ref.read(appCredentialsServiceProvider);
    try {
      final saved = await service.upsertUserEntry(entry);
      state = AsyncData(await service.getAll());
      return saved;
    } catch (error, stackTrace) {
      logError(
        'Failed to save app credentials: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Удаляет пользовательскую запись и обновляет список.
  Future<void> deleteUserEntry(String id) async {
    final service = ref.read(appCredentialsServiceProvider);
    try {
      await service.deleteUserEntry(id);
      state = AsyncData(await service.getAll());
    } catch (error, stackTrace) {
      logError(
        'Failed to delete app credentials: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      rethrow;
    }
  }
}
