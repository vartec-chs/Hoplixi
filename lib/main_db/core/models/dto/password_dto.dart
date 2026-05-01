import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/core/models/dto/tag_dto.dart';

part 'password_dto.freezed.dart';
part 'password_dto.g.dart';

/// DTO для создания нового пароля
@freezed
sealed class CreatePasswordDto with _$CreatePasswordDto {
  const factory CreatePasswordDto({
    required String name,
    required String password,
    String? login,
    String? email,
    String? url,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
    DateTime? expireAt,
  }) = _CreatePasswordDto;

  factory CreatePasswordDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePasswordDtoFromJson(json);
}

/// DTO для получения полной информации о пароле
@freezed
sealed class GetPasswordDto with _$GetPasswordDto {
  const factory GetPasswordDto({
    required String id,
    required String name,
    required String password,
    String? login,
    String? email,
    String? url,
    String? description,
    String? noteId,
    String? categoryId,
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime modifiedAt,
    DateTime? lastAccessedAt,
    required List<String> tags,
    DateTime? expireAt,
  }) = _GetPasswordDto;

  factory GetPasswordDto.fromJson(Map<String, dynamic> json) =>
      _$GetPasswordDtoFromJson(json);
}

/// DTO для карточки пароля (основная информация для отображения)
@freezed
sealed class PasswordCardDto with _$PasswordCardDto implements BaseCardDto {
  const factory PasswordCardDto({
    required String id,
    required String name,
    String? description,
    String? login,
    String? email,
    String? url,
    String? iconSource,
    String? iconValue,
    CategoryInCardDto? category,
    required bool isFavorite,
    required bool isPinned,

    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    required DateTime createdAt,
    List<TagInCardDto>? tags,
    DateTime? expireAt,
  }) = _PasswordCardDto;

  factory PasswordCardDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordCardDtoFromJson(json);
}

/// Группа записей, у которых совпадает значение пароля.
///
/// Сам пароль намеренно не хранится в DTO и не передается в UI.
class DuplicatePasswordGroupDto {
  const DuplicatePasswordGroupDto({required this.items});

  final List<PasswordCardDto> items;

  int get count => items.length;
}

/// DTO для обновления пароля
@freezed
sealed class UpdatePasswordDto with _$UpdatePasswordDto {
  const factory UpdatePasswordDto({
    String? name,
    String? password,
    String? login,
    String? email,
    String? url,
    String? description,
    String? noteId,
    String? categoryId,
    String? iconSource,
    String? iconValue,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
    DateTime? expireAt,
  }) = _UpdatePasswordDto;

  factory UpdatePasswordDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePasswordDtoFromJson(json);
}
