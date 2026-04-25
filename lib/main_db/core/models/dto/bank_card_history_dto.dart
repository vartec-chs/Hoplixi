import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_card_history_dto.freezed.dart';
part 'bank_card_history_dto.g.dart';

/// DTO для создания записи истории банковской карты
@freezed
sealed class CreateBankCardHistoryDto with _$CreateBankCardHistoryDto {
  const factory CreateBankCardHistoryDto({
    required String originalCardId,
    required String action,
    required String name,
    required String cardholderName,
    String? cardNumber,
    String? cardType,
    String? cardNetwork,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
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
  }) = _CreateBankCardHistoryDto;

  factory CreateBankCardHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateBankCardHistoryDtoFromJson(json);
}

/// DTO для получения записи из истории банковской карты
@freezed
sealed class GetBankCardHistoryDto with _$GetBankCardHistoryDto {
  const factory GetBankCardHistoryDto({
    required String id,
    required String originalCardId,
    required String action,
    required String name,
    required String cardholderName,
    String? cardNumber,
    String? cardType,
    String? cardNetwork,
    String? expiryMonth,
    String? expiryYear,
    String? bankName,
    String? accountNumber,
    String? routingNumber,
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
  }) = _GetBankCardHistoryDto;

  factory GetBankCardHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetBankCardHistoryDtoFromJson(json);
}

/// DTO для карточки истории банковской карты (основная информация)
@freezed
sealed class BankCardHistoryCardDto with _$BankCardHistoryCardDto {
  const factory BankCardHistoryCardDto({
    required String id,
    required String originalCardId,
    required String action,
    required String name,
    required String cardholderName,
    String? cardType,
    String? cardNetwork,
    required DateTime actionAt,
  }) = _BankCardHistoryCardDto;

  factory BankCardHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$BankCardHistoryCardDtoFromJson(json);
}
