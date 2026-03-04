import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_code_item_dto.freezed.dart';
part 'recovery_code_item_dto.g.dart';

/// DTO для отдельного кода восстановления из таблицы `recovery_codes`.
@freezed
sealed class RecoveryCodeItemDto with _$RecoveryCodeItemDto {
  const factory RecoveryCodeItemDto({
    required int id,
    required String itemId,
    required String code,
    required bool used,
    DateTime? usedAt,
    int? position,
  }) = _RecoveryCodeItemDto;

  factory RecoveryCodeItemDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodeItemDtoFromJson(json);
}
