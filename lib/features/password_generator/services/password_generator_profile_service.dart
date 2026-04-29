import 'dart:convert';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_generator/models/password_generator_profile.dart';
import 'package:hoplixi/features/password_generator/utils/password_generator_profiles_file.dart';
import 'package:uuid/uuid.dart';

class PasswordGeneratorProfileService {
  PasswordGeneratorProfileService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String _logTag = 'PasswordGeneratorProfileService';

  final Uuid _uuid;

  Future<PasswordGeneratorProfilesDocument> loadDocument() async {
    try {
      final file = await resolvePasswordGeneratorProfilesFile();
      if (!await file.exists()) {
        return const PasswordGeneratorProfilesDocument();
      }

      final rawContent = await file.readAsString();
      if (rawContent.trim().isEmpty) {
        return const PasswordGeneratorProfilesDocument();
      }

      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Profiles JSON must be an object');
      }

      return PasswordGeneratorProfilesDocument.fromJson(decoded);
    } catch (error, stackTrace) {
      logError(
        'Failed to load password generator profiles: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return const PasswordGeneratorProfilesDocument();
    }
  }

  Future<List<PasswordGeneratorProfile>> getProfiles() async {
    final document = await loadDocument();
    return document.profiles;
  }

  Future<PasswordGeneratorProfilesDocument> saveProfile({
    String? profileId,
    required String name,
    required int length,
    required bool useLowercase,
    required bool useUppercase,
    required bool useDigits,
    required bool useSpecial,
    required String lowercaseCharacters,
    required String uppercaseCharacters,
    required String digitCharacters,
    required String specialCharacters,
  }) async {
    final document = await loadDocument();
    final now = DateTime.now();
    final normalizedName = name.trim();
    final resolvedId = profileId ?? _uuid.v4();
    final existingIndex = document.profiles.indexWhere(
      (profile) => profile.id == resolvedId,
    );

    final existingProfile = existingIndex >= 0
        ? document.profiles[existingIndex]
        : null;

    final nextProfile = PasswordGeneratorProfile(
      id: resolvedId,
      name: normalizedName,
      length: length,
      useLowercase: useLowercase,
      useUppercase: useUppercase,
      useDigits: useDigits,
      useSpecial: useSpecial,
      lowercaseCharacters: lowercaseCharacters,
      uppercaseCharacters: uppercaseCharacters,
      digitCharacters: digitCharacters,
      specialCharacters: specialCharacters,
      createdAt: existingProfile?.createdAt ?? now,
      updatedAt: now,
    );

    final nextProfiles = [...document.profiles];
    if (existingIndex >= 0) {
      nextProfiles[existingIndex] = nextProfile;
    } else {
      nextProfiles.add(nextProfile);
    }

    nextProfiles.sort((left, right) {
      final nameComparison = left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      );
      if (nameComparison != 0) {
        return nameComparison;
      }
      return left.createdAt.compareTo(right.createdAt);
    });

    final nextDocument = document.copyWith(
      profiles: nextProfiles,
      lastSelectedProfileId: nextProfile.id,
    );

    await _writeDocument(nextDocument);
    return nextDocument;
  }

  Future<PasswordGeneratorProfilesDocument> deleteProfile(
    String profileId,
  ) async {
    final document = await loadDocument();
    final nextProfiles = document.profiles
        .where((profile) => profile.id != profileId)
        .toList(growable: false);

    final nextDocument = document.copyWith(
      profiles: nextProfiles,
      lastSelectedProfileId: document.lastSelectedProfileId == profileId
          ? null
          : document.lastSelectedProfileId,
    );

    await _writeDocument(nextDocument);
    return nextDocument;
  }

  Future<void> rememberSelectedProfile(String? profileId) async {
    final document = await loadDocument();
    final nextDocument = document.copyWith(lastSelectedProfileId: profileId);
    await _writeDocument(nextDocument);
  }

  Future<void> _writeDocument(
    PasswordGeneratorProfilesDocument document,
  ) async {
    final file = await resolvePasswordGeneratorProfilesFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(document.toJson()),
      flush: true,
    );
    logInfo('Password generator profiles saved', tag: _logTag);
  }
}
