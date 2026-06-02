import 'package:hoplixi/vault_db/core/models/dto/filter_meta_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/icon_dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/system/icons/icon_refs.dart';

/// Factory helpers and extension getters used by dashboard card widgets
/// when working with the new vault DTO model.
///
/// These are intentionally separate from the DTO definitions so the DTO
/// files stay free of UI-specific concerns.
extension IconRefDtoFactoryX on IconRefDto {
  /// Builds an [IconRefDto] from the legacy `(iconSource, iconValue)` field
  /// pair that older card widgets used to expose.
  ///
  /// Returns `null` when both inputs are `null`/empty.
  static IconRefDto? fromFields({String? iconSource, String? iconValue}) {
    final hasSource = iconSource != null && iconSource.isNotEmpty;
    final hasValue = iconValue != null && iconValue.isNotEmpty;
    if (!hasSource && !hasValue) return null;

    return IconRefDto(
      iconSourceType: _parseIconSourceType(iconSource),
      iconValue: hasValue ? iconValue : null,
    );
  }

  static IconSourceType _parseIconSourceType(String? raw) {
    if (raw == null || raw.isEmpty) return IconSourceType.builtin;
    for (final value in IconSourceType.values) {
      if (value.name == raw) return value;
    }
    return IconSourceType.builtin;
  }
}

/// Resolves an [IconRefDto] for a category by falling back to the
/// category's color (so cards still display a visual identifier when the
/// category has no `iconRefId`).
extension CategoryInCardDtoX on CategoryInCardDto {
  /// Returns a synthetic [IconRefDto] that uses the category color as a
  /// background swatch. This is the safe default when a card has no
  /// `iconRefId` of its own.
  IconRefDto? get effectiveIconRef {
    if (color == null) return null;
    return IconRefDto(iconSourceType: IconSourceType.builtin, color: color);
  }
}
