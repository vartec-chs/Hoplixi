import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/old/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_db/core/old/models/dto/category_dto.dart';
import 'package:hoplixi/main_db/core/old/models/dto/tag_dto.dart';

part 'loyalty_card_dto.freezed.dart';
part 'loyalty_card_dto.g.dart';

@freezed
sealed class CreateLoyaltyCardDto with _$CreateLoyaltyCardDto {
  const factory CreateLoyaltyCardDto({
    required String name,
    required String programName,
    String? cardNumber,
    String? holderName,
    String? barcodeValue,
    String? barcodeType,
    String? password,
    String? pointsBalance,
    String? tier,
    DateTime? expiryDate,
    String? website,
    String? phoneNumber,
    String? description,
    String? noteId,
    String? categoryId,
    required List<String> tagsIds,
  }) = _CreateLoyaltyCardDto;

  factory CreateLoyaltyCardDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLoyaltyCardDtoFromJson(json);
}



@freezed
sealed class GetLoyaltyCardDto with _$GetLoyaltyCardDto {
  const factory GetLoyaltyCardDto({
    required String id,
    required String name,
    required String programName,
    String? cardNumber,
    String? holderName,
    String? barcodeValue,
    String? barcodeType,
    String? password,
    String? pointsBalance,
    String? tier,
    DateTime? expiryDate,
    String? website,
    String? phoneNumber,
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
  }) = _GetLoyaltyCardDto;

  factory GetLoyaltyCardDto.fromJson(Map<String, dynamic> json) =>
      _$GetLoyaltyCardDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardCardDto
    with _$LoyaltyCardCardDto
    implements BaseCardDto {
  const factory LoyaltyCardCardDto({
    required String id,
    required String name,
    String? iconSource,
    String? iconValue,
    required String programName,
    String? cardNumber,
    String? holderName,
    String? barcodeValue,
    String? barcodeType,
    String? password,
    String? pointsBalance,
    String? tier,
    DateTime? expiryDate,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    required DateTime createdAt,
  }) = _LoyaltyCardCardDto;

  factory LoyaltyCardCardDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardCardDtoFromJson(json);
}

