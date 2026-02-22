import 'package:freezed_annotation/freezed_annotation.dart';

part 'wifi_history_dto.freezed.dart';
part 'wifi_history_dto.g.dart';

@freezed
sealed class WifiHistoryCardDto with _$WifiHistoryCardDto {
  const factory WifiHistoryCardDto({
    required String id,
    required String originalWifiId,
    required String action,
    required String name,
    required String ssid,
    String? security,
    required bool hidden,
    int? priority,
    required DateTime actionAt,
  }) = _WifiHistoryCardDto;

  factory WifiHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$WifiHistoryCardDtoFromJson(json);
}
