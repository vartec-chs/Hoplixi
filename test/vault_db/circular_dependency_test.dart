import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/vault_db/core/api/vault_core_api.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/db_state.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';

void main() {
  group('Riverpod Providers Graph Integrity Tests', () {
    late VaultDB inMemoryDb;

    setUp(() {
      inMemoryDb = VaultDB(DatabaseConnection(NativeDatabase.memory()));
    });

    tearDown(() async {
      await inMemoryDb.close();
    });

    test(
      'Проверка отсутствия циклических зависимостей при чтении vaultStoreApiProvider',
      () async {
        final now = DateTime.now();
        final fakeStoreInfo = StoreInfoDto(
          id: 'test-vault-id',
          name: 'Test Vault',
          description: 'Test Description',
          createdAt: now,
          modifiedAt: now,
          lastOpenedAt: now,
        );

        final Session fakeSession = (
          api: VaultCoreApi(inMemoryDb),
          info: fakeStoreInfo,
          storeDirectoryPath: '/fake/store/directory/path',
        );

        // Инициализируем контейнер провайдеров с переопределениями базовых провайдеров сессии БД.
        final container = ProviderContainer(
          overrides: [
            vaultDBSessionProvider.overrideWith((ref) async => fakeSession),
            vaultDBProvider.overrideWith((ref) async => inMemoryDb),
            vaultDBStateProvider.overrideWith(
              (ref) async => const DatabaseState(
                path: '/fake/store/directory/path',
                status: DatabaseStatus.open,
              ),
            ),
          ],
        );

        addTearDown(container.dispose);

        // Запускаем чтение всех ключевых провайдеров цепочки.
        // Если в графе есть циклическая зависимость, Riverpod выбросит CircularDependencyError во время выполнения ref.read.

        final storeApi = await container.read(vaultStoreApiProvider.future);
        expect(storeApi, isNotNull);

        final fileStorageService = await container.read(
          fileStorageServiceProvider.future,
        );
        expect(fileStorageService, isNotNull);

        final entityServices = await container.read(vaultEntityServices.future);
        expect(entityServices, isNotNull);
      },
    );
  });
}
