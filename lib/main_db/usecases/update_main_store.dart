import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart' hide Session;
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/models/session.dart';
import 'package:hoplixi/main_db/usecases/utils/error_handling.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

class UpdateMainStore {
  static const String _logTag = 'UpdateMainStore';

  final Uuid _uuid;

  UpdateMainStore({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  AsyncResultDart<StoreInfoDto, AppError> call({
    required Session session,
    required UpdateStoreDto dto,
  }) async {
    try {
      logInfo(
        'Updating store metadata',
        tag: _logTag,
        data: {'storeId': session.info.id, 'path': session.storeDirectoryPath},
      );

      final currentMeta = await session.store.storeMetaDao.getStoreMeta();
      if (currentMeta == null) {
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.recordNotFound,
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      var updatedMeta = currentMeta.copyWith(modifiedAt: DateTime.now());

      if (dto.name != null) {
        updatedMeta = updatedMeta.copyWith(name: dto.name);
      }

      if (dto.description != null) {
        updatedMeta = updatedMeta.copyWith(description: Value(dto.description));
      }

      if (dto.password != null) {
        final newSalt = _uuid.v4();
        final newPasswordHash = _hashPassword(dto.password!, newSalt);
        updatedMeta = updatedMeta.copyWith(
          passwordHash: newPasswordHash,
          salt: newSalt,
        );
      }

      await session.store
          .update(session.store.storeMetaTable)
          .replace(updatedMeta);

      return Success(
        StoreInfoDto(
          id: updatedMeta.id,
          name: updatedMeta.name,
          description: updatedMeta.description,
          createdAt: updatedMeta.createdAt,
          modifiedAt: updatedMeta.modifiedAt,
          lastOpenedAt: updatedMeta.lastOpenedAt,
          version: updatedMeta.version,
        ),
      );
    } catch (error, stackTrace) {
      return handleMainStoreUseCaseError(
        message: 'Failed to update store',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha512.convert(bytes).toString();
  }
}
