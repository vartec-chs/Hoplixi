import 'dart:async';
import 'package:result_dart/result_dart.dart';

/// Утилиты для работы с [ResultDart].
class ResultUtils {
  /// Обработать исключение синхронно и вернуть [ResultDart].
  static ResultDart<T, E> tryCatch<T extends Object, E extends Object>(
    T Function() operation,
    E Function(Object error, StackTrace stackTrace) errorMapper,
  ) {
    try {
      return Success(operation());
    } catch (error, stackTrace) {
      return Failure(errorMapper(error, stackTrace));
    }
  }

  /// Обработать асинхронное исключение и вернуть [Future<ResultDart>].
  static Future<ResultDart<T, E>>
  tryCatchAsync<T extends Object, E extends Object>(
    FutureOr<T> Function() operation,
    E Function(Object error, StackTrace stackTrace) errorMapper,
  ) async {
    try {
      return Success(await operation());
    } catch (error, stackTrace) {
      return Failure(errorMapper(error, stackTrace));
    }
  }

  /// Условно создать результат.
  static ResultDart<T, E> when<T extends Object, E extends Object>(
    bool condition,
    T Function() onTrue,
    E Function() onFalse,
  ) {
    return condition ? Success(onTrue()) : Failure(onFalse());
  }

  /// Преобразовать nullable значение в результат.
  static ResultDart<T, E> fromNullable<T extends Object, E extends Object>(
    T? value,
    E Function() errorOnNull,
  ) {
    return value != null ? Success(value) : Failure(errorOnNull());
  }

  /// Преобразовать Future<T?> в Future<ResultDart<T, E>>.
  static Future<ResultDart<T, E>> fromNullableAsync<
    T extends Object,
    E extends Object
  >(Future<T?> future, E Function() errorOnNull) async {
    final value = await future;
    return value != null ? Success(value) : Failure(errorOnNull());
  }

  /// Обработать список операций и вернуть результат первой ошибки.
  static Future<ResultDart<List<T>, E>> sequence<
    T extends Object,
    E extends Object
  >(List<Future<ResultDart<T, E>> Function()> operations) async {
    final results = <T>[];

    for (final operation in operations) {
      final result = await operation();
      if (result.isError()) {
        return Failure(result.exceptionOrNull() as E);
      }
      results.add(result.getOrThrow());
    }

    return Success(results);
  }

  /// Выполнить несколько результатов параллельно.
  static Future<ResultDart<List<T>, E>> parallel<
    T extends Object,
    E extends Object
  >(List<Future<ResultDart<T, E>>> futures) async {
    final results = await Future.wait(futures);

    for (final result in results) {
      if (result.isError()) {
        return Failure(result.exceptionOrNull() as E);
      }
    }

    final values = results.map((r) => r.getOrThrow()).toList();
    return Success(values);
  }
}
