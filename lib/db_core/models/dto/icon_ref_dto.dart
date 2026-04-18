import 'package:hoplixi/db_core/models/enums/icon_source.dart';

class IconRefDto {
  const IconRefDto({required this.source, required this.value});

  final IconSourceType source;
  final String value;

  factory IconRefDto.db(String value) {
    return IconRefDto(source: IconSourceType.db, value: value);
  }

  factory IconRefDto.iconPack(String value) {
    return IconRefDto(source: IconSourceType.iconPack, value: value);
  }

  factory IconRefDto.fromJson(Map<String, dynamic> json) {
    final source = IconSourceTypeX.tryParse(json['source'] as String?);
    final value = (json['value'] as String?)?.trim();
    if (source == null || value == null || value.isEmpty) {
      throw ArgumentError.value(json, 'json', 'Invalid icon ref json');
    }

    return IconRefDto(source: source, value: value);
  }

  static IconRefDto? fromFields({
    String? iconSource,
    String? iconValue,
    String? legacyIconId,
  }) {
    final normalizedValue = iconValue?.trim();
    final parsedSource = IconSourceTypeX.tryParse(iconSource);
    if (parsedSource != null &&
        normalizedValue != null &&
        normalizedValue.isNotEmpty) {
      return IconRefDto(source: parsedSource, value: normalizedValue);
    }

    final legacyValue = legacyIconId?.trim();
    if (legacyValue != null && legacyValue.isNotEmpty) {
      return IconRefDto.db(legacyValue);
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
    'source': source.value,
    'value': value,
  };

  String get sourceValue => source.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconRefDto &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          value == other.value;

  @override
  int get hashCode => Object.hash(source, value);

  @override
  String toString() => 'IconRefDto(source: ${source.value}, value: $value)';
}
