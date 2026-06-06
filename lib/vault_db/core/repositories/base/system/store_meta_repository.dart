import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';

import '../../../errors/db_error.dart';
import '../../../errors/db_result.dart';
import '../../../models/dto/system/store_meta_dto.dart';

class StoreMetaRepository {
  final VaultDB db;

  StoreMetaRepository(this.db);

  /// Получить метаданные хранилища.
  AsyncDBResult<StoreMetaDto> getStoreMeta() {
    return tryCatchAsync(
      () async {
        final data = await db.storeMetaDao.getStoreMeta();
        if (data == null) {
          throw const DBCoreError.notFound(
            entity: 'store_meta',
            id: 'singleton',
            message: 'Метаданные хранилища не инициализированы',
          );
        }
        return data;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении метаданных',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  ///Создать метаданные хранилища (вызывается при создании нового хранилища).
  AsyncDBResult<Unit> createStoreMeta(CreateStoreMetaDto dto) {
    return tryCatchAsync(
      () async {
        await db.storeMetaDao.createStoreMeta(dto);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.conflict(
              code: 'store_meta.create_failed',
              message:
                  'Не удалось создать метаданные хранилища (возможно, уже существуют)',
              data: {'error': e.toString()},
            ),
    );
  }

  /// Проверить, создано ли хранилище.
  AsyncDBResult<bool> hasStore() {
    return tryCatchAsync(
      () => db.storeMetaDao.hasStoreMeta(),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при проверке наличия хранилища',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  /// Обновить информацию о хранилище (имя, описание).
  AsyncDBResult<Unit> updateInfo({required String name, String? description}) {
    return tryCatchAsync(
      () async {
        final rows = await db.storeMetaDao.updateStoreMeta(
          StoreMetaTableCompanion(
            name: Value(name),
            description: Value(description),
            modifiedAt: Value(DateTime.now()),
          ),
        );

        if (rows == 0) {
          throw const DBCoreError.notFound(
            entity: 'store_meta',
            id: 'singleton',
          );
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении информации о хранилище',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  /// Сменить пароль базы данных через PRAGMA rekey.
  AsyncDBResult<Unit> changePassword(String newPragmaKey) {
    return db.storeMetaDao.changePassword(newPragmaKey);
  }

  /// Обновить хэш пароля и соль в метаданных.
  AsyncDBResult<Unit> updatePasswordHash({
    required String newPasswordHash,
    required String newSalt,
  }) {
    return db.storeMetaDao.updatePasswordHash(
      newPasswordHash: newPasswordHash,
      newSalt: newSalt,
    );
  }

  /// Обновить время последнего открытия (вызывается при входе).
  AsyncDBResult<Unit> updateLastOpened() {
    return tryCatchAsync(
      () async {
        await db.storeMetaDao.updateStoreMeta(
          StoreMetaTableCompanion(lastOpenedAt: Value(DateTime.now())),
        );
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.sqlite(message: e.toString(), cause: e, stackTrace: st),
    );
  }

  /// Полная инициализация метаданных (вызывается при создании нового хранилища).
  AsyncDBResult<Unit> initStore(StoreMetaTableCompanion companion) {
    return tryCatchAsync(
      () async {
        // Гарантируем, что singletonId всегда 1
        final finalCompanion = companion.copyWith(
          singletonId: const Value(1),
          createdAt: Value(DateTime.now()),
          modifiedAt: Value(DateTime.now()),
          lastOpenedAt: Value(DateTime.now()),
        );

        await db.storeMetaDao.insertStoreMeta(finalCompanion);
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.conflict(
              code: 'store.init_failed',
              message:
                  'Не удалось инициализировать хранилище (возможно, уже существует)',
              data: {'error': e.toString()},
            ),
    );
  }

  /// Получить краткую информацию о хранилище (без секретных данных).
  AsyncDBResult<StoreInfoDto> getStoreInfo() {
    return tryCatchAsync(
      () async {
        final data = await db.storeMetaDao.getStoreInfo();

        if (data == null) {
          throw const DBCoreError.notFound(
            entity: 'store_meta',
            id: 'singleton',
            message: 'Информация о хранилище не найдена',
          );
        }

        return data;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении информации о хранилище',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  /// Получить ключ для вложений (encryption key).
  AsyncDBResult<String> getAttachmentKey() {
    return tryCatchAsync(
      () async {
        final key = await db.storeMetaDao.getAttachmentKey();

        if (key == null) {
          throw const DBCoreError.notFound(
            entity: 'store_meta',
            id: 'attachment_key',
            message: 'Attachment key не найден',
          );
        }

        return key;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении attachment key',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  /// Получить хэш пароля хранилища.
  AsyncDBResult<String> getPasswordHash() {
    return tryCatchAsync(
      () async {
        final hash = await db.storeMetaDao.getPasswordHash();

        if (hash == null) {
          throw const DBCoreError.notFound(
            entity: 'store_meta',
            id: 'password_hash',
            message: 'Password hash не найден',
          );
        }

        return hash;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении password hash',
              cause: e,
              stackTrace: st,
            ),
    );
  }
}
