import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_store/main_store_manager.dart';
import 'package:hoplixi/main_store/models/db_history_model.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';
import 'package:hoplixi/main_store/services/db_key_derivation_service.dart';
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

class FakeDbHistoryService extends Fake implements DatabaseHistoryService {
  final entries = <String, DatabaseEntry>{};

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
      password: password,
      savePassword: savePassword,
      createdAt: DateTime.now(),
      lastAccessed: null,
    );
    entries[path] = entry;
    return entry;
  }

  @override
  Future<DatabaseEntry?> getByPath(String path) async {
    return entries[path];
  }
}

class FakeDbKeyService extends Fake implements DbKeyDerivationService {
  @override
  Future<String> derivePragmaKey(
    String password,
    String salt, {
    bool useDeviceKey = false,
  }) async {
    // Return a regular string password, which will trigger the legacy code path
    return 'my_secure_password';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeDbHistoryService historyService;
  late FakeDbKeyService keyService;
  late MainStoreManager manager;

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

      final keyConfig = File(p.join(storeDir.path, 'store_key.json'));
      expect(keyConfig.existsSync(), isTrue);

      final attachmentsDir = Directory(p.join(storeDir.path, 'attachments'));
      expect(attachmentsDir.existsSync(), isTrue);

      // Verify history was recorded
      expect(historyService.entries.containsKey(storeDir.path), isTrue);
      final historyEntry = historyService.entries[storeDir.path]!;
      expect(historyEntry.name, 'Test Store');
      expect(
        historyEntry.password,
        'secure_password_123',
      ); // because saveMasterPassword is true
    });

    test('fails if a store with same normalized name already exists', () async {
      final dto = const CreateStoreDto(
        name: 'Another Store',
        path: '',
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
        password: 'pass',
      );

      await manager.createStore(dto);
      expect(manager.isStoreOpen, isTrue);

      // Act
      final dto2 = const CreateStoreDto(
        name: 'Store 2',
        path: '',
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
