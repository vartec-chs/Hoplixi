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
