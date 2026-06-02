import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart' hide Session;
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'package:hoplixi/vault_db/usecases/utils/error_handling.dart';
import 'package:result_dart/result_dart.dart';

class UpdateVaultDB {
  static const String _logTag = 'UpdateVaultDB';

  UpdateVaultDB();

  AsyncResultDart<StoreInfoDto, AppError> call({
    required Session session,
    required PatchStoreDto dto,
  }) async {
    try {
      logInfo(
        'Updating store metadata',
        tag: _logTag,
        data: {'storeId': session.info.id, 'path': session.storeDirectoryPath},
      );

      final currentMeta = await session.api.db.storeMetaDao.getStoreMeta();
      if (currentMeta == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.recordNotFound,
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      String? name;
      Value<String?> description = const Value.absent();
      String? passwordHash;
      final now = DateTime.now();

      if (dto.name.isSet) {
        name = dto.name.requireValue();
      }

      if (dto.description.isSet) {
        description = Value(dto.description.requireValue());
      }

      if (dto.password.isSet) {
        passwordHash = _hashPassword(dto.password.requireValue()!);
      }

      await session.api.db.storeMetaDao.patchStoreMeta(
        name: name,
        description: description,
        passwordHash: passwordHash,
        modifiedAt: now,
      );

      return Success(
        StoreInfoDto(
          id: currentMeta.id,
          name: name ?? currentMeta.name,
          description: dto.description.isSet
              ? dto.description.requireValue()
              : currentMeta.description,
          createdAt: currentMeta.createdAt,
          modifiedAt: now,
          lastOpenedAt: currentMeta.lastOpenedAt,
        ),
      );
    } catch (error, stackTrace) {
      return handleVaultDBUseCaseError(
        message: 'Failed to update store',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha512.convert(bytes).toString();
  }
}
