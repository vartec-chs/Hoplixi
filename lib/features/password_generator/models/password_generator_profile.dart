import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_generator_profile.freezed.dart';
part 'password_generator_profile.g.dart';

@freezed
sealed class PasswordGeneratorProfile with _$PasswordGeneratorProfile {
  const factory PasswordGeneratorProfile({
    required String id,
    required String name,
    required int length,
    required bool useLowercase,
    required bool useUppercase,
    required bool useDigits,
    required bool useSpecial,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PasswordGeneratorProfile;

  factory PasswordGeneratorProfile.fromJson(Map<String, dynamic> json) =>
      _$PasswordGeneratorProfileFromJson(json);
}

@freezed
sealed class PasswordGeneratorProfilesDocument
    with _$PasswordGeneratorProfilesDocument {
  const factory PasswordGeneratorProfilesDocument({
    @Default(1) int schemaVersion,
    @Default(<PasswordGeneratorProfile>[])
    List<PasswordGeneratorProfile> profiles,
    String? lastSelectedProfileId,
  }) = _PasswordGeneratorProfilesDocument;

  factory PasswordGeneratorProfilesDocument.fromJson(
    Map<String, dynamic> json,
  ) => _$PasswordGeneratorProfilesDocumentFromJson(json);
}
