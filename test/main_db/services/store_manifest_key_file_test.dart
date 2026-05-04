import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/main_db/services/vault_key_file_service.dart';
import 'package:hoplixi/main_db/usecases/open_main_store.dart';

void main() {
  group('StoreManifest key file metadata', () {
    test('serializes and deserializes without key file', () {
      final manifest = _manifest();

      final json = manifest.toJson();
      final restored = StoreManifest.fromJson(json);

      expect(json['useKeyFile'], isFalse);
      expect(json['keyFileId'], isNull);
      expect(json['keyFileHint'], isNull);
      expect(restored.useKeyFile, isFalse);
      expect(restored.keyFileId, isNull);
      expect(restored.keyFileHint, isNull);
    });

    test('old JSON without useKeyFile defaults to false', () {
      final json = _manifest().toJson()
        ..remove('useKeyFile')
        ..remove('keyFileId')
        ..remove('keyFileHint');

      final restored = StoreManifest.fromJson(json);

      expect(restored.useKeyFile, isFalse);
      expect(restored.keyFileId, isNull);
      expect(restored.keyFileHint, isNull);
    });

    test('useKeyFile true requires keyFileId', () {
      expect(
        () => _manifest(useKeyFile: true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('disabling key file clears keyFileId and keyFileHint', () {
      final manifest = _manifest(
        useKeyFile: true,
        keyFileId: 'key-file-id',
        keyFileHint: 'USB key file',
      );

      final disabled = manifest.withoutKeyFile();

      expect(disabled.useKeyFile, isFalse);
      expect(disabled.keyFileId, isNull);
      expect(disabled.keyFileHint, isNull);
    });

    test('manifest does not contain key file secret material', () {
      final keyFile = VaultKeyFile.generate(hint: 'USB key file');
      final secret = base64UrlEncode(keyFile.secret);
      final manifest = _manifest(
        useKeyFile: true,
        keyFileId: keyFile.id,
        keyFileHint: keyFile.hint,
      );

      final manifestText = jsonEncode(manifest.toJson());

      expect(manifestText, isNot(contains(secret)));
      expect(manifestText, isNot(contains('secret')));
      expect(manifestText, isNot(contains('/tmp/key-file.json')));
    });
  });

  group('VaultKeyFile parser', () {
    test('accepts v1 key file', () {
      final keyFile = VaultKeyFile.generate(hint: 'USB key file');

      final restored = VaultKeyFile.fromJson(keyFile.toJson());

      expect(restored.version, VaultKeyFile.currentVersion);
      expect(restored.id, keyFile.id);
      expect(restored.secret, keyFile.secret);
      expect(restored.hint, 'USB key file');
    });

    test('rejects malformed or short secrets', () {
      expect(
        () => VaultKeyFile.fromJson({
          'version': 1,
          'id': 'key-file-id',
          'secret': base64UrlEncode([1, 2, 3]),
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => VaultKeyFile.fromJson({
          'version': 1,
          'id': 'key-file-id',
          'secret': 'not valid base64',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('OpenMainStore key file validation', () {
    test('returns validation error when selected key file id mismatches', () {
      final manifest = _manifest(
        useKeyFile: true,
        keyFileId: 'expected-id',
        keyFileHint: 'USB key file',
      );
      final keyFile = VaultKeyFile.generate();

      final error = OpenMainStore.validateKeyFileForOpen(
        dto: OpenStoreDto(
          path: 'store.db',
          password: 'password',
          keyFileId: 'selected-id',
          keyFileSecret: keyFile.secret,
        ),
        manifest: manifest,
      );

      expect(error, isNotNull);
      expect(error!.isValidation, isTrue);
    });
  });
}

StoreManifest _manifest({
  bool useKeyFile = false,
  String? keyFileId,
  String? keyFileHint,
}) {
  return StoreManifest.initial(
    lastMigrationVersion: MainConstants.databaseSchemaVersion,
    appVersion: '1.0.0',
    storeUuid: 'store-id',
    storeName: 'Store',
    updatedAt: DateTime.utc(2026, 1, 1),
    lastModifiedBy: const StoreManifestLastModifiedBy(
      deviceId: 'device-id',
      clientInstanceId: 'client-id',
      appVersion: '1.0.0',
    ),
    useKeyFile: useKeyFile,
    keyFileId: keyFileId,
    keyFileHint: keyFileHint,
  );
}
