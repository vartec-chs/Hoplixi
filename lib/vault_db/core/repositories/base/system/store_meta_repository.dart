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
  Future<DbResult<StoreMetaDto>> getStoreMeta() async {
    try {
      final data = await db.storeMetaDao.getStoreMeta();
      if (data == null) {
        return const Failure(
          DBCoreError.notFound(
            entity: 'store_meta',
            id: 'singleton',
            message: 'Метаданные хранилища не инициализированы',
          ),
        );
      }
      return Success(data);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(
          message: 'Ошибка при получении метаданных',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  ///Создать метаданные хранилища (вызывается при создании нового хранилища).
  Future<DbResult<Unit>> createStoreMeta(CreateStoreMetaDto dto) async {
    try {
      await db.storeMetaDao.createStoreMeta(dto);
      return const Success(unit);
    } catch (e) {
      return Failure(
        DBCoreError.conflict(
          code: 'store_meta.create_failed',
          message:
              'Не удалось создать метаданные хранилища (возможно, уже существуют)',
          data: {'error': e.toString()},
        ),
      );
    }
  }

  /// Проверить, создано ли хранилище.
  Future<DbResult<bool>> hasStore() async {
    try {
      final exists = await db.storeMetaDao.hasStoreMeta();
      return Success(exists);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(
          message: 'Ошибка при проверке наличия хранилища',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Обновить информацию о хранилище (имя, описание).
  Future<DbResult<Unit>> updateInfo({
    required String name,
    String? description,
  }) async {
    try {
      final rows = await db.storeMetaDao.updateStoreMeta(
        StoreMetaTableCompanion(
          name: Value(name),
          description: Value(description),
          modifiedAt: Value(DateTime.now()),
        ),
      );

      return rows > 0
          ? const Success(unit)
          : const Failure(
              DBCoreError.notFound(entity: 'store_meta', id: 'singleton'),
            );
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(
          message: 'Ошибка при обновлении информации о хранилище',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Обновить время последнего открытия (вызывается при входе).
  Future<DbResult<Unit>> updateLastOpened() async {
    try {
      await db.storeMetaDao.updateStoreMeta(
        StoreMetaTableCompanion(lastOpenedAt: Value(DateTime.now())),
      );
      return const Success(unit);
    } catch (e, st) {
      return Failure(
        DBCoreError.sqlite(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  /// Полная инициализация метаданных (вызывается при создании нового хранилища).
  Future<DbResult<Unit>> initStore(StoreMetaTableCompanion companion) async {
    try {
      // Гарантируем, что singletonId всегда 1
      final finalCompanion = companion.copyWith(
        singletonId: const Value(1),
        createdAt: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
        lastOpenedAt: Value(DateTime.now()),
      );

      await db.storeMetaDao.insertStoreMeta(finalCompanion);
      return const Success(unit);
    } catch (e) {
      return Failure(
        DBCoreError.conflict(
          code: 'store.init_failed',
          message:
              'Не удалось инициализировать хранилище (возможно, уже существует)',
          data: {'error': e.toString()},
        ),
      );
    }
  }

  /// Получить краткую информацию о хранилище (без секретных данных).
  Future<DbResult<StoreInfoDto>> getStoreInfo() async {
    try {
      final data = await db.storeMetaDao.getStoreInfo();

      if (data == null) {
        return const Failure(
          DBCoreError.notFound(
            entity: 'store_meta',
            id: 'singleton',
            message: 'Информация о хранилище не найдена',
          ),
        );
      }

      return Success(data);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(
          message: 'Ошибка при получении информации о хранилище',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Получить ключ для вложений (encryption key).
  Future<DbResult<String>> getAttachmentKey() async {
    try {
      final key = await db.storeMetaDao.getAttachmentKey();

      if (key == null) {
        return const Failure(
          DBCoreError.notFound(
            entity: 'store_meta',
            id: 'attachment_key',
            message: 'Attachment key не найден',
          ),
        );
      }

      return Success(key);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(
          message: 'Ошибка при получении attachment key',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Получить хэш пароля хранилища.
  Future<DbResult<String>> getPasswordHash() async {
    try {
      final hash = await db.storeMetaDao.getPasswordHash();

      if (hash == null) {
        return const Failure(
          DBCoreError.notFound(
            entity: 'store_meta',
            id: 'password_hash',
            message: 'Password hash не найден',
          ),
        );
      }

      return Success(hash);
    } catch (e, st) {
      return Failure(
        DBCoreError.unknown(
          message: 'Ошибка при получении password hash',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
