import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/vault_db/core/api/vault_core_api.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/services/main_store_storage_service.dart';
import 'package:hoplixi/vault_db/services/session/vault_session_holder.dart';
import 'package:hoplixi/vault_db/services/storage/vault_storage_manager.dart';

class FakeVaultSessionHolder extends VaultSessionHolder {
  String? fakePath;

  @override
  String? get currentStorePath => fakePath ?? super.currentStorePath;
}

void main() {
  group('VaultSessionHolder Tests', () {
    late VaultSessionHolder sessionHolder;
    late VaultDB inMemoryDb;
    late Session fakeSession;

    setUp(() {
      sessionHolder = VaultSessionHolder();
      inMemoryDb = VaultDB(DatabaseConnection(NativeDatabase.memory()));

      final now = DateTime.now();
      final storeInfo = StoreInfoDto(
        id: 'test-id',
        name: 'Test Store',
        description: 'Test Desc',
        createdAt: now,
        modifiedAt: now,
        lastOpenedAt: now,
      );

      fakeSession = (
        api: VaultCoreApi(inMemoryDb),
        info: storeInfo,
        storeDirectoryPath: '/path/to/store',
      );
    });

    tearDown(() async {
      sessionHolder.dispose();
      await inMemoryDb.close();
    });

    test('Изначально сессия закрыта', () {
      expect(sessionHolder.isStoreOpen, isFalse);
      expect(sessionHolder.currentSession, isNull);
      expect(sessionHolder.currentDB, isNull);
      expect(sessionHolder.currentStorePath, isNull);
    });

    test('updateSession успешно открывает сессию и обновляет геттеры', () {
      sessionHolder.updateSession(fakeSession);

      expect(sessionHolder.isStoreOpen, isTrue);
      expect(sessionHolder.currentSession, equals(fakeSession));
      expect(sessionHolder.currentDB, equals(inMemoryDb));
      expect(sessionHolder.currentStorePath, equals('/path/to/store'));
    });

    test('clearSession успешно закрывает сессию', () {
      sessionHolder.updateSession(fakeSession);
      sessionHolder.clearSession();

      expect(sessionHolder.isStoreOpen, isFalse);
      expect(sessionHolder.currentSession, isNull);
    });

    test('sessionStream транслирует изменения состояния сессии', () async {
      final states = <Session?>[];
      final subscription = sessionHolder.sessionStream.listen(states.add);

      sessionHolder.updateSession(fakeSession);
      sessionHolder.clearSession();

      // Даем микрозадачам выполниться, чтобы стрим успел доставить события
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
      expect(states[0], equals(fakeSession));
      expect(states[1], isNull);

      await subscription.cancel();
    });
  });

  group('VaultStorageManager Tests', () {
    late FakeVaultSessionHolder sessionHolder;
    late VaultStorageManager storageManager;
    const storageService = VaultDBFileService();

    setUp(() {
      sessionHolder = FakeVaultSessionHolder();
      storageManager = VaultStorageManager(
        sessionHolder: sessionHolder,
        storageService: storageService,
      );
    });

    test('getAttachmentsPath возвращает null, если сессия закрыта', () {
      sessionHolder.fakePath = null;
      expect(storageManager.getAttachmentsPath(), isNull);
    });

    test(
      'getAttachmentsPath возвращает правильный путь, если сессия открыта',
      () {
        sessionHolder.fakePath = '/path/to/store';
        final path = storageManager.getAttachmentsPath();
        expect(path, isNotNull);
        expect(path, contains('attachments'));
        expect(path, contains('/path/to/store'));
      },
    );

    test('getDecryptedAttachmentsPath возвращает правильный путь', () {
      sessionHolder.fakePath = '/path/to/store';
      final path = storageManager.getDecryptedAttachmentsPath();
      expect(path, isNotNull);
      expect(path, contains('attachments_decrypted'));
      expect(path, contains('/path/to/store'));
    });
  });
}
