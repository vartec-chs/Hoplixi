import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_update.freezed.dart';

/// Обертка для частичного обновления полей в Patch DTO.
///
/// Позволяет отличить три состояния:
/// 1. Не менять (keep)
/// 2. Установить значение, включая null (set)
@freezed
sealed class FieldUpdate<T> with _$FieldUpdate<T> {
  const factory FieldUpdate.keep() = FieldUpdateKeep<T>;
  const factory FieldUpdate.set(T? value) = FieldUpdateSet<T>;
}

extension FieldUpdateDriftX<T> on FieldUpdate<T> {
  Value<T?> toNullableValue() {
    return switch (this) {
      FieldUpdateKeep<T>() => const Value.absent(),
      FieldUpdateSet<T>(value: final value) => Value(value),
    };
  }
}

extension FieldUpdateRequiredDriftX<T extends Object> on FieldUpdate<T> {
  Value<T> toRequiredValue() {
    return switch (this) {
      FieldUpdateKeep<T>() => const Value.absent(),
      FieldUpdateSet<T>(value: final value) =>
        value == null
            ? throw ArgumentError('Required field cannot be set to null')
            : Value(value),
    };
  }
}

extension FieldUpdateX<T> on FieldUpdate<T> {
  /// Возвращает значение если это set, иначе fallback.
  T? get valueOrNull {
    return switch (this) {
      FieldUpdateKeep<T>() => null,
      FieldUpdateSet<T>(value: final value) => value,
    };
  }

  /// true если поле нужно обновить.
  bool get isSet => switch (this) {
    FieldUpdateKeep<T>() => false,
    FieldUpdateSet<T>() => true,
  };

  /// true если keep.
  bool get isKeep => !isSet;

  /// Получить значение только если set.
  /// Бросает ошибку если keep.
  T? requireValue() {
    return switch (this) {
      FieldUpdateKeep<T>() => throw StateError('FieldUpdate is keep'),
      FieldUpdateSet<T>(value: final value) => value,
    };
  }
}
