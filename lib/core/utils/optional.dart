/// Опциональное значение (аналог nullable, но совместимый с типами, требующими non-nullable).
sealed class Optional<T extends Object> {
  const Optional();

  /// Создать Optional из значения.
  ///
  /// Если значение null, вернет None.
  factory Optional.fromNullable(T? value) =>
      value != null ? Some(value) : const None();

  /// Получить значение или null.
  T? getOrNull();

  /// Проверить наличие значения.
  bool get isPresent;

  /// Проверить отсутствие значения.
  bool get isEmpty => !isPresent;

  /// Выполнить действие в зависимости от наличия значения.
  R fold<R>(R Function(T value) onSome, R Function() onNone);
}

/// Содержит значение.
class Some<T extends Object> extends Optional<T> {
  final T value;
  const Some(this.value);

  @override
  T? getOrNull() => value;

  @override
  bool get isPresent => true;

  @override
  R fold<R>(R Function(T value) onSome, R Function() onNone) => onSome(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Some<T> &&
          runtimeType == other.runtimeType &&
          value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Some($value)';
}

/// Значение отсутствует.
class None<T extends Object> extends Optional<T> {
  const None();

  @override
  T? getOrNull() => null;

  @override
  bool get isPresent => false;

  @override
  R fold<R>(R Function(T value) onSome, R Function() onNone) => onNone();

  @override
  bool operator ==(Object other) => other is None;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'None';
}
