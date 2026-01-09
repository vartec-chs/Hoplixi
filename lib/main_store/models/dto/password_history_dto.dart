import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_history_dto.freezed.dart';
part 'password_history_dto.g.dart';

/// DTO для создания записи истории пароля
@freezed
sealed class CreatePasswordHistoryDto with _$CreatePasswordHistoryDto {
  const factory CreatePasswordHistoryDto({
    required String originalPasswordId,
    required String action,
    required String name,
    String? login,
    String? email,
    String? url,
    String? description,
    String? noteId,
    String? password,
    String? categoryName,
    String? tags,
    int? usedCount,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    bool? isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    DateTime? lastAccessedAt,
  }) = _CreatePasswordHistoryDto;

  factory CreatePasswordHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePasswordHistoryDtoFromJson(json);
}

/// DTO для получения записи из истории пароля
@freezed
sealed class GetPasswordHistoryDto with _$GetPasswordHistoryDto {
  const factory GetPasswordHistoryDto({
    required String id,
    required String originalPasswordId,
    required String action,
    required String name,
    String? login,
    String? email,
    String? url,
    String? description,
    String? noteId,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    required DateTime actionAt,
  }) = _GetPasswordHistoryDto;

  factory GetPasswordHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetPasswordHistoryDtoFromJson(json);
}

/// DTO для карточки истории пароля (основная информация)
@freezed
sealed class PasswordHistoryCardDto with _$PasswordHistoryCardDto {
  const factory PasswordHistoryCardDto({
    required String id,
    required String originalPasswordId,
    required String action,
    required String name,
    String? login,
    String? email,
    required DateTime actionAt,
  }) = _PasswordHistoryCardDto;

  factory PasswordHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordHistoryCardDtoFromJson(json);
}
