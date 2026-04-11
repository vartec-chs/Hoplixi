import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/db_core/main_store_manager.dart';
import 'package:hoplixi/db_core/models/db_ciphers.dart';
import 'package:hoplixi/db_core/models/db_history_model.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/services/db_history_services.dart';
import 'package:hoplixi/db_core/services/db_key_derivation_service.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  final String appSupportPath;
  final String appDocsPath;

  FakePathProviderPlatform({
    required this.tempPath,
    required this.appSupportPath,
    required this.appDocsPath,
  });

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => appSupportPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => appDocsPath;
}

class FakeDeviceInfoPlatform extends DeviceInfoPlatform {
  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    return WindowsDeviceInfo(
      computerName: 'test-pc',
      numberOfCores: 8,
      systemMemoryInMegabytes: 16384,
      userName: 'tester',
      majorVersion: 10,
      minorVersion: 0,
      buildNumber: 22631,
      platformId: 2,
      csdVersion: '',
      servicePackMajor: 0,
      servicePackMinor: 0,
      suitMask: 0,
      productType: 1,
      reserved: 0,
      buildLab: '22631.test',
      buildLabEx: '22631.1.amd64fre.test',
      digitalProductId: Uint8List.fromList(List<int>.filled(16, 1)),
      displayVersion: '23H2',
      editionId: 'Professional',
      installDate: DateTime(2024, 1, 1),
      productId: '00000-00000-00000-AAAAA',
      productName: 'Windows Test',
      registeredOwner: 'Test Owner',
      releaseId: '23H2',
      deviceId: 'device-test-id',
    );
  }
}

class FakeDbHistoryService extends Fake implements DatabaseHistoryService {
  final entries = <String, DatabaseEntry>{};
  final savedPasswords = <String, String>{};

  @override
  Future<DatabaseEntry> create({
    required String path,
    required String dbId,
    required String name,
    String? description,
    String? password,
    bool savePassword = false,
  }) async {
    final entry = DatabaseEntry(
      dbId: dbId,
      path: path,
      name: name,
      description: description,
      savePassword: savePassword,
      createdAt: DateTime.now(),
      lastAccessed: null,
    );
    entries[path] = entry;
    if (savePassword && password != null && password.isNotEmpty) {
      savedPasswords[path] = password;
    }
    return entry;
  }

  @override
  Future<DatabaseEntry?> getByPath(String path) async {
    return entries[path];
  }

  @override
  Future<DatabaseEntry> update(DatabaseEntry entry) async {
    entries[entry.path] = entry;
    if (!entry.savePassword) {
      savedPasswords.remove(entry.path);
    }
    return entry;
  }

  @override
  Future<String?> getSavedPasswordByPath(String path) async {
    final entry = entries[path];
    if (entry == null || !entry.savePassword) {
      return null;
    }
    return savedPasswords[path];
  }

  @override
  Future<void> setSavedPasswordByPath(String path, String? password) async {
    if (password == null || password.isEmpty) {
      savedPasswords.remove(path);
      return;
    }
    savedPasswords[path] = password;
  }
}

class FakeDbKeyService extends Fake implements DbKeyDerivationService {
  @override
  Future<String> derivePragmaKey(
    String password,
    String salt, {
    bool useDeviceKey = false,
  }) async {
    return 'my_secure_password';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeDbHistoryService historyService;
  late FakeDbKeyService keyService;
  late MainStoreManager manager;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'hoplixi_test',
      packageName: 'dev.hoplixi.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    DeviceInfoPlatform.instance = FakeDeviceInfoPlatform();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hoplixi_test_');

    // Setup fake path provider
    PathProviderPlatform.instance = FakePathProviderPlatform(
      tempPath: p.join(tempDir.path, 'temp'),
      appSupportPath: p.join(tempDir.path, 'support'),
      appDocsPath: p.join(tempDir.path, 'docs'),
    );

    historyService = FakeDbHistoryService();
    keyService = FakeDbKeyService();
    manager = MainStoreManager(historyService, keyService);
  });

  tearDown(() async {
    if (manager.isStoreOpen) {
      await manager.closeStore();
    }
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MainStoreManager.createStore', () {
    test('successfully creates a new store', () async {
      // Arrange
      final dto = const CreateStoreDto(
        name: 'Test Store',
        path: '',
        description: 'A test store description',
        password: 'secure_password_123',
        saveMasterPassword: true,
        cipher: DBCipher.chacha20,
        useDeviceKey: false,
      );

      // Act
      final result = await manager.createStore(dto);

      // Assert
      expect(
        result.isSuccess(),
        isTrue,
        reason: result.exceptionOrNull()?.toString(),
      );

      final info = result.getOrThrow();
      expect(info.name, 'Test Store'); // Name is normalized (spaces removed)
      expect(info.description, 'A test store description');

      expect(manager.isStoreOpen, isTrue);
      expect(manager.currentStorePath, isNotNull);

      // Verify files were created
      final storeDir = Directory(manager.currentStorePath!);
      expect(storeDir.existsSync(), isTrue);

      final dbFile = File(p.join(storeDir.path, 'test_store.hplxdb'));
      expect(dbFile.existsSync(), isTrue);

      final manifest = await StoreManifestService.readFrom(storeDir.path);
      expect(manifest, isNotNull);
      expect(manifest?.keyConfig?.argon2Salt, isNotEmpty);
      expect(manifest?.keyConfig?.useDeviceKey, isFalse);
      expect(manifest?.keyConfig?.cipher, DBCipher.chacha20);

      final attachmentsDir = Directory(p.join(storeDir.path, 'attachments'));
      expect(attachmentsDir.existsSync(), isTrue);

      // Verify history was recorded
      expect(historyService.entries.containsKey(storeDir.path), isTrue);
      final historyEntry = historyService.entries[storeDir.path]!;
      expect(historyEntry.name, 'Test Store');
      expect(historyEntry.savePassword, isTrue);
      expect(
        historyService.savedPasswords[storeDir.path],
        'secure_password_123',
      );
    });

    test('fails if a store with same normalized name already exists', () async {
      final dto = const CreateStoreDto(
        name: 'Another Store',
        path: '',
        cipher: DBCipher.chacha20,

        password: 'pass',
      );

      // Act - First creation
      final result1 = await manager.createStore(dto);
      expect(result1.isSuccess(), isTrue);
      await manager.closeStore();

      // Act - Second creation with same name
      final identicalDto = const CreateStoreDto(
        name: 'Another Store',
        path: '',
        cipher: DBCipher.chacha20,

        password: 'pass',
      );
      final result2 = await manager.createStore(identicalDto);

      // Assert
      expect(result2.isError(), isTrue);
      expect(
        result2.exceptionOrNull()?.message,
        'Хранилище с таким именем уже существует',
      );
    });

    test('fails if store is already open', () async {
      // Arrange
      final dto = const CreateStoreDto(
        name: 'Store 1',
        path: '',
        cipher: DBCipher.chacha20,

        password: 'pass',
      );

      await manager.createStore(dto);
      expect(manager.isStoreOpen, isTrue);

      // Act
      final dto2 = const CreateStoreDto(
        name: 'Store 2',
        path: '',
        cipher: DBCipher.chacha20,

        password: 'pass',
      );
      final result = await manager.createStore(dto2);

      // Assert
      expect(result.isError(), isTrue);
      expect(
        result.exceptionOrNull()?.message,
        contains('Хранилище уже открыто'),
      );
    });
  });
}
