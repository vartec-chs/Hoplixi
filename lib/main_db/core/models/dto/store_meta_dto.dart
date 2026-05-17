import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_meta_dto.freezed.dart';
part 'store_meta_dto.g.dart';

@freezed
sealed class StoreMetaDto with _$StoreMetaDto {
  const factory StoreMetaDto({
    required String id,
    required String name,
    String? description,
    required String passwordHash,
    required String salt,
    required String attachmentKey,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime lastOpenedAt,
  }) = _StoreMetaDto;

  factory StoreMetaDto.fromJson(Map<String, dynamic> json) =>
      _$StoreMetaDtoFromJson(json);
}
