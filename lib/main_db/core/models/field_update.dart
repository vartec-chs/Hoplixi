import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' show Value;

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