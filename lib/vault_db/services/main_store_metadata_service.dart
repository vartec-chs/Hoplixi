import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

/// Сервис работы с метаданными VaultDB.
class VaultDBMetadataService {
  final Uuid _uuid;

  VaultDBMetadataService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<String> createStoreMetadata({
    required VaultDB database,
    required String name,
    required String password,
    String? description,
  }) async {
    final salt = _uuid.v4();
    final passwordHash = _hashPassword(password, salt);
    final attachmentKey = _generateSecureKey();

    return database.storeMetaDao.createStoreMeta(
      name: name,
      description: description,
      passwordHash: passwordHash,
      salt: salt,
      attachmentKey: attachmentKey,
    );
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

      var updatedMeta = currentMeta.copyWith(modifiedAt: DateTime.now());

      if (dto.name.valueOrNull != null) {
        updatedMeta = updatedMeta.copyWith(name: dto.name.valueOrNull);
      }

      if (dto.description.valueOrNull != null) {
        updatedMeta = updatedMeta.copyWith(
          description: Value(dto.description.valueOrNull),
        );
      }

      if (dto.password.valueOrNull != null) {
        final newSalt = _uuid.v4();
        final newPasswordHash = _hashPassword(
          dto.password.valueOrNull!,
          newSalt,
        );
        updatedMeta = updatedMeta.copyWith(
          passwordHash: newPasswordHash,
          salt: newSalt,
        );
      }

      await database.update(database.storeMetaTable).replace(updatedMeta);

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

  StoreInfoDto _toStoreInfoDto(StoreMeta meta) {
    return StoreInfoDto(
      id: meta.id,
      name: meta.name,
      description: meta.description,
      createdAt: meta.createdAt,
      modifiedAt: meta.modifiedAt,
      lastOpenedAt: meta.lastOpenedAt,
      version: meta.version,
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
