import 'package:riverpod/src/framework.dart';

import '../constants/main_constants.dart';
import 'app_logger.dart';

final class LoggingProviderObserver extends ProviderObserver {
  static const String _logTag = 'RiverpodObserver';

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    logInfo(
      '[RIVERPOD] ➕ ADD   ${context.provider.name ?? context.provider.runtimeType} = ${MainConstants.isProduction ? '[PROD]' : value}',
      tag: _logTag,
    );
    super.didAddProvider(context, value);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    logInfo(
      '[RIVERPOD] ❌ DISPOSE ${context.provider.name ?? context.provider.runtimeType}',
      tag: _logTag,
    );
    super.didDisposeProvider(context);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (MainConstants.isProduction) {
      super.didUpdateProvider(context, previousValue, newValue);
      return;
    }

    logInfo(
      '[RIVERPOD] ⬆️ UPDATE ${context.provider.name ?? context.provider.runtimeType}: $previousValue → $newValue',
      tag: _logTag,
    );
    super.didUpdateProvider(context, previousValue, newValue);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      '[RIVERPOD] ⚠️ ERROR  ${context.provider.name ?? context.provider.runtimeType}: $error',
      stackTrace: stackTrace,
      tag: _logTag,
    );
    super.providerDidFail(context, error, stackTrace);
  }

  void didFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    logError(
      '[RIVERPOD] ⚠️ ERROR  ${provider.name ?? provider.runtimeType}: $error',
      stackTrace: stackTrace,
      tag: _logTag,
    );
  }

  @override
  void mutationSuccess(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
    Object? result,
  ) {
    logInfo(
      '[RIVERPOD] ✅ MUTATION ${context.provider.name ?? context.provider.runtimeType}: $mutation → ${MainConstants.isProduction ? '[PROD]' : result}',
      tag: _logTag,
    );
    super.mutationSuccess(context, mutation, result);
  }

  @override
  void mutationError(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      '[RIVERPOD] ⚠️ MUTATION ERROR ${context.provider.name ?? context.provider.runtimeType}: $mutation → ${MainConstants.isProduction ? '[PROD]' : error}',
      stackTrace: stackTrace,
      tag: _logTag,
    );
    super.mutationError(context, mutation, error, stackTrace);
  }

  @override
  void mutationReset(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
  ) {
    logInfo(
      '[RIVERPOD] 🔄 MUTATION RESET ${context.provider.name ?? context.provider.runtimeType}: ${MainConstants.isProduction ? '[PROD]' : mutation}',
      tag: _logTag,
    );
    super.mutationReset(context, mutation);
  }

  @override
  void mutationStart(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
  ) {
    logInfo(
      '[RIVERPOD] 🔄 MUTATION START ${context.provider.name ?? context.provider.runtimeType}: ${MainConstants.isProduction ? '[PROD]' : mutation}',
      tag: _logTag,
    );
    super.mutationStart(context, mutation);
  }
}
