import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'crypto_wallet_dto.freezed.dart';
part 'crypto_wallet_dto.g.dart';

@freezed
sealed class CreateCryptoWalletDto with _$CreateCryptoWalletDto {
  const factory CreateCryptoWalletDto({
    required String name,
    required String walletType,
    String? mnemonic,
    String? privateKey,
    String? derivationPath,
    String? network,
    String? addresses,
    String? xpub,
    String? xprv,
    String? hardwareDevice,
    DateTime? lastBalanceCheckedAt,
    String? notesOnUsage,
    bool? watchOnly,
    String? derivationScheme,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateCryptoWalletDto;

  factory CreateCryptoWalletDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCryptoWalletDtoFromJson(json);
}

@freezed
sealed class UpdateCryptoWalletDto with _$UpdateCryptoWalletDto {
  const factory UpdateCryptoWalletDto({
    String? name,
    String? walletType,
    String? mnemonic,
    String? privateKey,
    String? derivationPath,
    String? network,
    String? addresses,
    String? xpub,
    String? xprv,
    String? hardwareDevice,
    DateTime? lastBalanceCheckedAt,
    String? notesOnUsage,
    bool? watchOnly,
    String? derivationScheme,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateCryptoWalletDto;

  factory UpdateCryptoWalletDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCryptoWalletDtoFromJson(json);
}

@freezed
sealed class CryptoWalletCardDto
    with _$CryptoWalletCardDto
    implements BaseCardDto {
  const factory CryptoWalletCardDto({
    required String id,
    required String name,
    required String walletType,
    String? network,
    String? derivationPath,
    String? hardwareDevice,
    DateTime? lastBalanceCheckedAt,
    required bool watchOnly,
    required bool hasMnemonic,
    required bool hasPrivateKey,
    required bool hasXpub,
    required bool hasXprv,
    String? description,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    required DateTime createdAt,
  }) = _CryptoWalletCardDto;

  factory CryptoWalletCardDto.fromJson(Map<String, dynamic> json) =>
      _$CryptoWalletCardDtoFromJson(json);
}
