import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/models/token_oauth.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/services/token_service.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/providers/token_service_provider.dart';

/// AsyncNotifier для управления списком OAuth токенов
///
/// Предоставляет состояние списка токенов и методы для создания, обновления и удаления токенов.
class TokenNotifier extends AsyncNotifier<List<TokenOAuth>> {
  late final TokenService _service;

  @override
  Future<List<TokenOAuth>> build() async {
    _service = ref.watch(tokenServiceProvider);

    // Инициализируем сервис, если не инициализирован
    final initResult = await _service.initialize();
    if (initResult.isError()) {
      throw initResult.exceptionOrNull()!;
    }

    // Получаем все токены
    final result = await _service.getAllTokens();
    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }

    return result.getOrNull() ?? [];
  }

  /// Создать новый токен
  Future<void> createToken(TokenOAuth token) async {
    state = const AsyncLoading();

    final result = await _service.createToken(token);
    if (result.isSuccess()) {
      // Обновляем состояние, добавляя новый токен
      final currentTokens = state.value ?? [];
      state = AsyncData([...currentTokens, token]);
    } else {
      // В случае ошибки возвращаем предыдущее состояние с ошибкой
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }

  /// Обновить токен
  Future<void> updateToken(TokenOAuth token) async {
    state = const AsyncLoading();

    final result = await _service.updateToken(token);
    if (result.isSuccess()) {
      // Обновляем состояние, заменяя токен
      final currentTokens = state.value ?? [];
      state = AsyncData(
        currentTokens.map((t) => t.id == token.id ? token : t).toList(),
      );
    } else {
      // В случае ошибки возвращаем предыдущее состояние с ошибкой
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }

  /// Удалить токен по ID
  Future<void> deleteToken(String id) async {
    state = const AsyncLoading();

    final result = await _service.deleteToken(id);
    if (result.isSuccess()) {
      // Обновляем состояние, удаляя токен
      final currentTokens = state.value ?? [];
      state = AsyncData(
        currentTokens.where((token) => token.id != id).toList(),
      );
    } else {
      // В случае ошибки возвращаем предыдущее состояние с ошибкой
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }

  /// Перезагрузить список токенов
  Future<void> reload() async {
    state = const AsyncLoading();

    final result = await _service.getAllTokens();
    if (result.isSuccess()) {
      state = AsyncData(result.getOrNull() ?? []);
    } else {
      state = AsyncError(result.exceptionOrNull()!, StackTrace.current);
    }
  }
}

/// Провайдер для управления OAuth токенами в UI
final tokenProvider = AsyncNotifierProvider<TokenNotifier, List<TokenOAuth>>(
  TokenNotifier.new,
);
