import 'package:result_dart/result_dart.dart';

/// Расширения и утилиты для работы с result_dart
///
/// Предоставляет удобные методы для обработки ошибок и преобразования результатов
extension ResultExtensions<S extends Object, F extends Object>
    on ResultDart<S, F> {
  /// Преобразовать успех в другой тип
  ///
  /// ```dart
  /// final result = Success(42);
  /// final transformed = result.mapSuccess((value) => value.toString());
  /// // transformed = Success("42")
  /// ```
  ResultDart<U, F> mapSuccess<U extends Object>(U Function(S success) mapper) {
    return fold(
      (success) => Success(mapper(success)),
      (error) => Failure(error),
    );
  }

  /// Преобразовать ошибку в другой тип
  ///
  /// ```dart
  /// final result = Failure(Exception('error'));
  /// final transformed = result.mapError((error) => error.toString());
  /// // transformed = Failure("Exception: error")
  /// ```
  ResultDart<S, U> mapError<U extends Object>(U Function(F error) mapper) {
    return fold(
      (success) => Success(success),
      (error) => Failure(mapper(error)),
    );
  }

  /// Получить успех или null если ошибка
  S? getSuccessOrNull() {
    return fold((success) => success, (_) => null);
  }

  /// Получить ошибку или null если успех
  F? getErrorOrNull() {
    return fold((_) => null, (error) => error);
  }

  /// Проверить является ли результат успехом
  bool isSuccess() => fold((_) => true, (_) => false);

  /// Проверить является ли результат ошибкой
  bool isError() => fold((_) => false, (_) => true);

  /// Выполнить функцию если результат - успех
  ResultDart<S, F> tapSuccess(void Function(S success) callback) {
    return fold((success) {
      callback(success);
      return Success(success);
    }, (error) => Failure(error));
  }

  /// Выполнить функцию если результат - ошибка
  ResultDart<S, F> tapError(void Function(F error) callback) {
    return fold((success) => Success(success), (error) {
      callback(error);
      return Failure(error);
    });
  }

  /// Преобразовать результат, применяя функцию к успеху
  ResultDart<U, F> flatMapSuccess<U extends Object>(
    ResultDart<U, F> Function(S success) mapper,
  ) {
    return fold((success) => mapper(success), (error) => Failure(error));
  }

  /// Преобразовать результат, применяя функцию к ошибке
  ResultDart<S, U> flatMapError<U extends Object>(
    ResultDart<S, U> Function(F error) mapper,
  ) {
    return fold((success) => Success(success), (error) => mapper(error));
  }

  /// Получить значение или значение по умолчанию если ошибка
  S getOrElse(S Function(F error) defaultValue) {
    return fold((success) => success, (error) => defaultValue(error));
  }

  /// Получить значение или выбросить исключение если ошибка
  S getOrThrow([String? message]) {
    return fold((success) => success, (error) {
      if (message != null) {
        throw Exception('$message: $error');
      }
      throw Exception(error);
    });
  }
}

/// Расширения для асинхронных результатов
extension AsyncResultExtensions<S extends Object, F extends Object>
    on AsyncResultDart<S, F> {
  /// Преобразовать успех в другой тип
  AsyncResultDart<U, F> mapSuccess<U extends Object>(
    U Function(S success) mapper,
  ) {
    return then((result) => result.mapSuccess(mapper));
  }

  /// Преобразовать ошибку в другой тип
  AsyncResultDart<S, U> mapError<U extends Object>(U Function(F error) mapper) {
    return then((result) => result.mapError(mapper));
  }

  /// Выполнить функцию если результат - успех
  AsyncResultDart<S, F> tapSuccess(void Function(S success) callback) {
    return then((result) => result.tapSuccess(callback));
  }

  /// Выполнить функцию если результат - ошибка
  AsyncResultDart<S, F> tapError(void Function(F error) callback) {
    return then((result) => result.tapError(callback));
  }

  /// Преобразовать результат, применяя функцию к успеху
  AsyncResultDart<U, F> flatMapSuccess<U extends Object>(
    AsyncResultDart<U, F> Function(S success) mapper,
  ) {
    return then(
      (result) => result.fold(
        (success) => mapper(success),
        (error) => Future.value(Failure(error)),
      ),
    );
  }

  /// Преобразовать результат, применяя функцию к ошибке
  AsyncResultDart<S, U> flatMapError<U extends Object>(
    AsyncResultDart<S, U> Function(F error) mapper,
  ) {
    return then(
      (result) => result.fold(
        (success) => Future.value(Success(success)),
        (error) => mapper(error),
      ),
    );
  }

  /// Получить значение или значение по умолчанию если ошибка
  Future<S> getOrElse(S Function(F error) defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }

  /// Получить значение или выбросить исключение если ошибка
  Future<S> getOrThrow() async {
    final result = await this;
    return result.getOrThrow();
  }
}

/// Утилиты для создания результатов
class ResultUtils {
  /// Обработать исключение синхронно и вернуть Result
  ///
  /// ```dart
  /// final result = ResultUtils.tryCatch(
  ///   () => int.parse('123'),
  ///   (error, stackTrace) => MyError.parse,
  /// );
  /// // result = Success(123)
  /// ```
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

  /// Обработать асинхронное исключение и вернуть Future<Result>
  ///
  /// ```dart
  /// final result = await ResultUtils.tryCatchAsync(
  ///   () => apiClient.fetchUser(id),
  ///   (error, stackTrace) => MyError.network,
  /// );
  /// // result = Success(user) или Failure(MyError.network)
  /// ```
  static Future<ResultDart<T, E>>
  tryCatchAsync<T extends Object, E extends Object>(
    Future<T> Function() operation,
    E Function(Object error, StackTrace stackTrace) errorMapper,
  ) async {
    try {
      return Success(await operation());
    } catch (error, stackTrace) {
      return Failure(errorMapper(error, stackTrace));
    }
  }

  /// Обработать список операций и вернуть результат первой ошибки
  ///
  /// Если все успешны, возвращает успех со списком всех значений
  ///
  /// ```dart
  /// final results = await ResultUtils.sequence([
  ///   () => apiClient.fetchUser(1),
  ///   () => apiClient.fetchUser(2),
  ///   () => apiClient.fetchUser(3),
  /// ]);
  /// ```
  static Future<ResultDart<List<T>, E>> sequence<
    T extends Object,
    E extends Object
  >(List<Future<ResultDart<T, E>> Function()> operations) async {
    final results = <T>[];

    for (final operation in operations) {
      final result = await operation();
      if (result.isError()) {
        return result.fold((_) => Success(results), (error) => Failure(error));
      }
      results.add(result.getOrThrow());
    }

    return Success(results);
  }

  /// Выполнить операцию и распространить ошибку если есть
  ///
  /// Полезно для преобразования типов ошибок
  static ResultDart<T, E> chainResult<
    T extends Object,
    E extends Object,
    F extends Object
  >(ResultDart<T, F> result, E Function(F error) errorMapper) {
    return result.fold(
      (success) => Success(success),
      (error) => Failure(errorMapper(error)),
    );
  }

  /// Выполнить асинхронную операцию и распространить ошибку если есть
  static AsyncResultDart<T, E> chainAsyncResult<
    T extends Object,
    E extends Object,
    F extends Object
  >(AsyncResultDart<T, F> result, E Function(F error) errorMapper) {
    return result.then(
      (r) => r.fold(
        (success) => Success(success),
        (error) => Failure(errorMapper(error)),
      ),
    );
  }

  /// Выполнить несколько результатов параллельно
  ///
  /// Возвращает ошибку первой неудачной операции
  static Future<ResultDart<List<T>, E>> parallel<
    T extends Object,
    E extends Object
  >(List<Future<ResultDart<T, E>>> futures) async {
    try {
      final results = await Future.wait(futures);

      for (final result in results) {
        if (result.isError()) {
          return result.fold(
            (_) => const Success([]),
            (error) => Failure(error),
          );
        }
      }

      final values = results.map((r) => r.getOrThrow()).toList();
      return Success(values);
    } catch (_) {
      // Этот catch срабатывает если Future.wait выбросит исключение
      rethrow;
    }
  }

  /// Создать успех
  static ResultDart<T, E> success<T extends Object, E extends Object>(T value) {
    return Success(value);
  }

  /// Создать ошибку
  static ResultDart<T, E> failure<T extends Object, E extends Object>(E error) {
    return Failure(error);
  }

  /// Условно создать результат
  static ResultDart<T, E> when<T extends Object, E extends Object>(
    bool condition,
    T Function() onTrue,
    E Function() onFalse,
  ) {
    return condition ? Success(onTrue()) : Failure(onFalse());
  }

  /// Преобразовать nullable значение в результат
  static ResultDart<T, E> fromNullable<T extends Object, E extends Object>(
    T? value,
    E Function() errorOnNull,
  ) {
    return value != null ? Success(value) : Failure(errorOnNull());
  }

  /// Преобразовать Future<T?> в Future<Result<T, E>>
  static Future<ResultDart<T, E>> fromNullableAsync<
    T extends Object,
    E extends Object
  >(Future<T?> future, E Function() errorOnNull) async {
    final value = await future;
    return value != null ? Success(value) : Failure(errorOnNull());
  }
}
