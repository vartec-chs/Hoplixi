import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/errors/extensions/db_core_error_to_app_error.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/repositories.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

/// Сервис работы с метаданными VaultDB.
class VaultDBMetadataService {
  final Uuid _uuid;

  VaultDBMetadataService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  AsyncResultDart<Unit, AppError> createStoreMetadata({
    required VaultDB database,
    required String name,
    required String password,
    String? description,
  }) async {
    final salt = _uuid.v4();
    final passwordHash = _hashPassword(password, salt);
    final attachmentKey = _generateSecureKey();

    final createDto = CreateStoreMetaDto(
      name: name,
      description: description,
      passwordSalt: salt,
      passwordHash: passwordHash,
      attachmentKey: attachmentKey,
    );

    return StoreMetaRepository(database).createStoreMeta(createDto).then((
      result,
    ) {
      if (result.isError()) {
        throw result.exceptionOrNull()!.toAppError();
      }
      return const Success(unit);
    });
  }

  AsyncResultDart<StoreInfoDto, AppError> getStoreInfo(VaultDB database) async {
    try {
      final metaResult = await getStoreMeta(database);
      if (metaResult.isError()) {
        return metaResult.fold(
          (_) => Failure(
            AppError.mainDatabase(
              code: MainDatabaseErrorCode.recordNotFound,
              message: 'Метаданные хранилища не найдены',
              timestamp: DateTime.now(),
            ),
          ),
          Failure.new,
        );
      }

      final meta = metaResult.getOrThrow();

      return Success(_toStoreInfoDto(meta));
    } catch (e, stackTrace) {
      return Failure(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.queryFailed,
          message: 'Не удалось получить информацию о хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  AsyncResultDart<StoreInfoDto, AppError> updateStore(
    VaultDB database,
    PatchStoreDto dto,
  ) async {
    try {
      final currentMetaResult = await getStoreMeta(database);
      if (currentMetaResult.isError()) {
        return currentMetaResult.fold(
          (_) => Failure(
            AppError.mainDatabase(
              code: MainDatabaseErrorCode.recordNotFound,
              message: 'Метаданные хранилища не найдены',
              timestamp: DateTime.now(),
            ),
          ),
          Failure.new,
        );
      }

      final currentMeta = currentMetaResult.getOrThrow();

      final now = DateTime.now();

      String? newPasswordHash;
      String? newSalt;

      if (dto.password is FieldUpdateSet<String>) {
        newSalt = _uuid.v4();
        newPasswordHash = _hashPassword(
          (dto.password as FieldUpdateSet<String>).value!,
          newSalt,
        );
      }

      final companion = StoreMetaTableCompanion(
        name: dto.name.toRequiredValue(),
        description: dto.description.toNullableValue(),
        passwordHash: newPasswordHash != null
            ? Value(newPasswordHash)
            : const Value.absent(),
        modifiedAt: Value(now),
      );

      await database.storeMetaDao.updateStoreMeta(companion);

      final updatedMeta = currentMeta.copyWith(
        name: dto.name.valueOrNull ?? currentMeta.name,
        description: dto.description.isSet
            ? dto.description.valueOrNull
            : currentMeta.description,
        passwordHash: newPasswordHash ?? currentMeta.passwordHash,
        modifiedAt: now,
      );

      return Success(_toStoreInfoDto(updatedMeta));
    } catch (e, stackTrace) {
      return Failure(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.updateFailed,
          message: 'Не удалось обновить хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  AsyncResultDart<StoreMetaDto, AppError> getStoreMeta(VaultDB database) async {
    try {
      final meta = await database.storeMetaDao.getStoreMeta();

      if (meta == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.recordNotFound,
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(meta);
    } catch (e, stackTrace) {
      return Failure(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.queryFailed,
          message: 'Не удалось получить метаданные хранилища: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> updateLastOpenedAt(VaultDB database) {
    return database.storeMetaDao.updateLastOpenedAt();
  }

  StoreInfoDto _toStoreInfoDto(dynamic meta) {
    if (meta is StoreMetaDto) {
      return StoreInfoDto(
        id: meta.id,
        name: meta.name,
        description: meta.description,
        createdAt: meta.createdAt,
        modifiedAt: meta.modifiedAt,
        lastOpenedAt: meta.lastOpenedAt,
      );
    }
    // Fallback if needed, though getStoreMeta returns StoreMetaDto
    return StoreInfoDto(
      id: meta.id as String,
      name: meta.name as String,
      description: meta.description as String?,
      createdAt: meta.createdAt as DateTime,
      modifiedAt: meta.modifiedAt as DateTime,
      lastOpenedAt: meta.lastOpenedAt as DateTime,
    );
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  String _generateSecureKey() {
    final bytes = generateSecureRandomBytes(32);
    return base64Encode(bytes);
  }

  Uint8List generateSecureRandomBytes(int length) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'Length must be positive');
    }
    final random = SecureRandom.fast;
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}
