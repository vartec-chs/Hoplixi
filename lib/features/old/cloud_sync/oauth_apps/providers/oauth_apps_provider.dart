import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/services/oauth_apps_service.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/providers/oauth_apps_service_provider.dart';

/// AsyncNotifier для управления списком OAuth приложений
///
/// Предоставляет состояние списка приложений и методы для создания и удаления приложений.
class OAuthAppsNotifier extends AsyncNotifier<List<OauthApps>> {
  late final OAuthAppsService _service;

  @override
  Future<List<OauthApps>> build() async {
    _service = ref.watch(oauthAppsServiceProvider);

    // Инициализируем сервис, если не инициализирован
    final initResult = await _service.initialize();
    if (initResult.isError()) {
      throw initResult.exceptionOrNull()!;
    }

    // Получаем все приложения
    final result = await _service.getAllApps();
    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }

    return result.getOrNull() ?? [];
  }

  /// Создать новое OAuth приложение
  Future<void> createApp(OauthApps app) async {
    state = const AsyncLoading();

    final result = await _service.createApp(app);
    if (result.isSuccess()) {
      // Обновляем состояние, добавляя новое приложение
      final currentApps = state.value ?? [];
      state = AsyncData([...currentApps, app]);
    } else {
      // В случае ошибки возвращаем предыдущее состояние с ошибкой
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }

  /// Обновить OAuth приложение
  Future<void> updateApp(OauthApps app) async {
    state = const AsyncLoading();

    final result = await _service.updateApp(app);
    if (result.isSuccess()) {
      // Обновляем состояние, заменяя приложение
      final currentApps = state.value ?? [];
      state = AsyncData(
        currentApps.map((a) => a.id == app.id ? app : a).toList(),
      );
    } else {
      // В случае ошибки возвращаем предыдущее состояние с ошибкой
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }

  /// Удалить OAuth приложение по ID
  Future<void> deleteApp(String id) async {
    state = const AsyncLoading();

    final result = await _service.deleteApp(id);
    if (result.isSuccess()) {
      // Обновляем состояние, удаляя приложение
      final currentApps = state.value ?? [];
      state = AsyncData(currentApps.where((app) => app.id != id).toList());
    } else {
      // В случае ошибки возвращаем предыдущее состояние с ошибкой
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }

  /// Перезагрузить список приложений
  Future<void> reload() async {
    state = const AsyncLoading();

    final result = await _service.getAllApps();
    if (result.isSuccess()) {
      state = AsyncData(result.getOrNull() ?? []);
    } else {
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }
}

/// Провайдер для управления OAuth приложениями в UI
final oauthAppsProvider =
    AsyncNotifierProvider<OAuthAppsNotifier, List<OauthApps>>(
      OAuthAppsNotifier.new,
    );
