import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_code_dto.freezed.dart';
part 'recovery_code_dto.g.dart';

@freezed
sealed class RecoveryCodeDto with _$RecoveryCodeDto {
  const factory RecoveryCodeDto({
    int? id,
    required String itemId,
    required String code,
    @Default(false) bool used,
    DateTime? usedAt,
    int? position,
  }) = _RecoveryCodeDto;

  factory RecoveryCodeDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodeDtoFromJson(json);
}
