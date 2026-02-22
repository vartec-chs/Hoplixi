import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'wifi_dto.freezed.dart';
part 'wifi_dto.g.dart';

@freezed
sealed class CreateWifiDto with _$CreateWifiDto {
  const factory CreateWifiDto({
    required String name,
    required String ssid,
    String? password,
    String? security,
    bool? hidden,
    String? eapMethod,
    String? username,
    String? identity,
    String? domain,
    String? lastConnectedBssid,
    int? priority,
    String? notes,
    String? qrCodePayload,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateWifiDto;

  factory CreateWifiDto.fromJson(Map<String, dynamic> json) =>
      _$CreateWifiDtoFromJson(json);
}

@freezed
sealed class UpdateWifiDto with _$UpdateWifiDto {
  const factory UpdateWifiDto({
    String? name,
    String? ssid,
    String? password,
    String? security,
    bool? hidden,
    String? eapMethod,
    String? username,
    String? identity,
    String? domain,
    String? lastConnectedBssid,
    int? priority,
    String? notes,
    String? qrCodePayload,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateWifiDto;

  factory UpdateWifiDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateWifiDtoFromJson(json);
}

@freezed
sealed class WifiCardDto with _$WifiCardDto implements BaseCardDto {
  const factory WifiCardDto({
    required String id,
    required String name,
    required String ssid,
    String? security,
    required bool hidden,
    String? eapMethod,
    int? priority,
    String? lastConnectedBssid,
    required bool hasPassword,
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
  }) = _WifiCardDto;

  factory WifiCardDto.fromJson(Map<String, dynamic> json) =>
      _$WifiCardDtoFromJson(json);
}
