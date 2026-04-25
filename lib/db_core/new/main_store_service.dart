import 'dart:io';

import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/new/models/dto/main_db_dto.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';

typedef Session = ({MainStore store, StoreInfoDto info});

class MainStoreService {
  static const String _logTag = 'MainStoreService';

  static const String attachmentsFolder = 'attachments';
  static const String decryptedAttachmentsFolder = 'attachments_decrypted';

  final Lock _lock = Lock();

  AsyncResultDart<Session, AppError> createStore(
    CreateStoreDto dto,
    String masterPassword,
  ) async {
    return _lock.synchronized(() async {
      try {
        final storagePath = await AppPaths.appStoragesPath;

        final normalizedName = normalizeStorageName(dto.name);
        final storageDir = Directory(p.join(storagePath, normalizedName));

        if (await storageDir.exists()) {
          final existingDbFile = await findDatabaseFile(storageDir.path);
          if (existingDbFile != null) {
            throw AppError.validation(
              code: ValidationErrorCode.alreadyExists,
              message: 'Хранилище с таким именем уже существует',
              data: {'path': storageDir.path},
              timestamp: DateTime.now(),
            );
          }

          await _moveDirectoryWithoutDatabase(
            baseStoragePath: storagePath,
            storeName: dto.name,
            storageDir: storageDir,
          );
        }

        await storageDir.create(recursive: true);
        logInfo('Created storage directory: ${storageDir.path}', tag: _logTag);

        await Directory(
          getAttachmentsPath(storageDir.path),
        ).create(recursive: true);
        logInfo('Created attachments directory', tag: _logTag);
      } catch (e, st) {
        return handleError(
          message: 'Failed to create store',
          error: e,
          stackTrace: st,
          tag: _logTag,
        );
      }
    });
  }

  AsyncResultDart<StoreInfoDto, AppError> openStore(
    OpenStoreDto dto,
    String masterPassword,
  ) async {
    throw UnimplementedError(
      'MainStoreManagerV2.openStore is not implemented yet',
    );
  }

  AsyncResultDart<StoreInfoDto, AppError> updateStore(
    String storeId,
    UpdateStoreDto dto,
  ) async {
    throw UnimplementedError(
      'MainStoreManagerV2.updateStore is not implemented yet',
    );
  }

  String getAttachmentsPath(String storePath) {
    return p.join(storePath, attachmentsFolder);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return p.join(storePath, decryptedAttachmentsFolder);
  }

  Future<bool> storageDirectoryExists(String path) async {
    return Directory(path).exists();
  }

  Future<void> deleteStorageDirectory(String path) async {
    await Directory(path).delete(recursive: true);
  }

  Failure<S, AppError> handleError<S extends Object>({
    required String message,
    required Object error,
    required StackTrace stackTrace,
    required String tag,
  }) {
    logError(message, error: error, stackTrace: stackTrace, tag: tag);

    return Failure<S, AppError>(
      AppError.mainDatabase(
        code: MainDatabaseErrorCode.unknown,
        message: message,
        stackTrace: stackTrace,
        data: {'exception': error.toString()},
        timestamp: DateTime.now(),
      ),
    );
  }

  String normalizeStorageName(String name) {
    var normalized = name.trim(); //
    normalized = normalized.replaceAll(
      RegExp(r'\s+'),
      '_',
    ); // убираем лишние пробелы и заменяем их на подчеркивания
    normalized = normalized.replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '',
    ); // удаляем недопустимые символы

    if (normalized.isEmpty) {
      throw AppError.validation(
        code: ValidationErrorCode.invalidInput,
        message: 'Имя хранилища содержит только недопустимые символы',
        data: {'originalName': name},
        timestamp: DateTime.now(),
      );
    }

    return normalized;
  }

  Future<String?> findDatabaseFile(String storagePath) async {
    try {
      final dir = Directory(storagePath);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith(MainConstants.dbExtension)) {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      logError('Failed to find database file: $e', tag: _logTag);
      return null;
    }
  }

  Future<void> _moveDirectoryWithoutDatabase({
    required String baseStoragePath,
    required String storeName,
    required Directory storageDir,
  }) async {
    final noSpacesName = storeName.replaceAll(RegExp(r'\s+'), '');
    final backupName = 'do_not_contain_db_file_$noSpacesName';
    var backupPath = p.join(baseStoragePath, backupName);

    var backupDir = Directory(backupPath);
    var counter = 1;
    while (await backupDir.exists()) {
      backupPath = p.join(baseStoragePath, '${backupName}_$counter');
      backupDir = Directory(backupPath);
      counter++;
    }

    await storageDir.rename(backupPath);
    logInfo('Renamed directory without db file to: $backupPath', tag: _logTag);
  }
}
