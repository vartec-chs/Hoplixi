import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hoplixi/vault_db/core/errors/db_exception_mapper.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/store_meta_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/store_meta_repository.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

/// Сервис для управления метаданными хранилища (имя, описание, пароли).
class StoreMetaService {
  final VaultDB db;
  final StoreMetaRepository repository;
  final Uuid _uuid;

  StoreMetaService({
    required this.db,
    StoreMetaRepository? repository,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       repository = repository ?? StoreMetaRepository(db);

  /// Получить информацию о хранилище.
  AsyncDBResult<StoreInfoDto> getStoreInfo() {
    return repository.getStoreInfo();
  }

  /// Получить полные метаданные (включая хэши).
  AsyncDBResult<StoreMetaDto> getStoreMeta() {
    return repository.getStoreMeta();
  }

  /// Обновить общую информацию (имя, описание).
  AsyncDBResult<Unit> updateInfo({required String name, String? description}) {
    return repository.updateInfo(name: name, description: description);
  }

  /// Сменить мастер-пароль хранилища.
  ///
  /// Выполняет `PRAGMA rekey` для смены ключа шифрования БД
  /// и обновляет проверочный хэш пароля в метаданных.
  AsyncDBResult<Unit> changePassword({
    required String newPassword,
    required String newPragmaKey,
  }) async {
    try {
      return await db.transaction(() async {
        // 1. Меняем ключ шифрования БД
        (await repository.changePassword(newPragmaKey)).getOrThrow();

        // 2. Генерируем новую соль и хэш для верификации
        final newSalt = _uuid.v4();
        final newHash = hashPassword(newPassword, newSalt);

        // 3. Обновляем хэш в метаданных
        (await repository.updatePasswordHash(
          newPasswordHash: newHash,
          newSalt: newSalt,
        )).getOrThrow();

        return const Success(unit);
      });
    } catch (e, st) {
      return Failure(mapDbException(e, st));
    }
  }

  /// Обновить время последнего открытия.
  AsyncDBResult<Unit> updateLastOpened() {
    return repository.updateLastOpened();
  }

  /// Вспомогательный метод для хэширования пароля.
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha512.convert(bytes).toString();
  }
}
