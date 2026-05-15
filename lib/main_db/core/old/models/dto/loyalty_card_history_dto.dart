import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_card_history_dto.freezed.dart';
part 'loyalty_card_history_dto.g.dart';

@freezed
sealed class CreateLoyaltyCardHistoryDto with _$CreateLoyaltyCardHistoryDto {
  const factory CreateLoyaltyCardHistoryDto({
    required String originalLoyaltyCardId,
    required String action,
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
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    DateTime? originalLastAccessedAt,
  }) = _CreateLoyaltyCardHistoryDto;

  factory CreateLoyaltyCardHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateLoyaltyCardHistoryDtoFromJson(json);
}

@freezed
sealed class GetLoyaltyCardHistoryDto with _$GetLoyaltyCardHistoryDto {
  const factory GetLoyaltyCardHistoryDto({
    required String id,
    required String originalLoyaltyCardId,
    required String action,
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
    String? categoryName,
    required int usedCount,
    required bool isFavorite,
    required bool isArchived,
    required bool isPinned,
    required bool isDeleted,
    required DateTime originalCreatedAt,
    required DateTime originalModifiedAt,
    DateTime? originalLastAccessedAt,
    required DateTime actionAt,
  }) = _GetLoyaltyCardHistoryDto;

  factory GetLoyaltyCardHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetLoyaltyCardHistoryDtoFromJson(json);
}

@freezed
sealed class LoyaltyCardHistoryCardDto with _$LoyaltyCardHistoryCardDto {
  const factory LoyaltyCardHistoryCardDto({
    required String id,
    required String originalLoyaltyCardId,
    required String action,
    required String name,
    required String programName,
    String? cardNumber,
    String? tier,
    required DateTime actionAt,
  }) = _LoyaltyCardHistoryCardDto;

  factory LoyaltyCardHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyCardHistoryCardDtoFromJson(json);
}

