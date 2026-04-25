import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/new/models/db_ciphers.dart';
import 'package:hoplixi/main_db/new/models/dto/main_db_dto.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:sqlite3/sqlite3.dart';

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
      MainStore? store;
      Directory? createdStorageDir;
      try {
        if (dto.useDeviceKey) {
          return Failure(
            AppError.validation(
              code: ValidationErrorCode.invalidInput,
              message:
                  'Создание стора с ключом устройства пока не поддерживается в MainStoreService',
              timestamp: DateTime.now(),
            ),
          );
        }

        final storagePath = dto.path.trim().isEmpty
            ? await AppPaths.appStoragesPath
            : dto.path.trim();

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
        createdStorageDir = storageDir;
        logInfo('Created storage directory: ${storageDir.path}', tag: _logTag);

        await Directory(
          getAttachmentsPath(storageDir.path),
        ).create(recursive: true);
        logInfo('Created attachments directory', tag: _logTag);

        final dbFilePath = p.join(
          storageDir.path,
          '$normalizedName${MainConstants.dbExtension}',
        );

        store = await _createMainStore(
          dbFilePath: dbFilePath,
          masterPassword: masterPassword,
          cipher: dto.cipher,
        );

        final info = await _createStoreMetadata(
          store: store,
          dto: dto,
          masterPassword: masterPassword,
        );

        logInfo('Store created successfully: ${dto.name}', tag: _logTag);
        return Success((store: store, info: info));
      } catch (e, st) {
        await store?.close();
        if (createdStorageDir != null) {
          try {
            await deleteStorageDirectory(createdStorageDir.path);
          } catch (cleanupError, cleanupStackTrace) {
            logWarning(
              'Failed to clean up storage directory after createStore error',
              tag: _logTag,
              data: {
                'error': cleanupError.toString(),
                'stackTrace': cleanupStackTrace.toString(),
              },
            );
          }
        }

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

  Future<MainStore> _createMainStore({
    required String dbFilePath,
    required String masterPassword,
    required DBCipher cipher,
  }) async {
    final dbFile = File(dbFilePath);
    final token = RootIsolateToken.instance;
    final setup = (Database rawDb) {
      _applyCipher(rawDb, cipher);
      rawDb.config.doubleQuotedStringLiterals = false;
      _registerSqlFunctions(rawDb);
      _applyPragmaKey(rawDb, masterPassword);
      rawDb.execute('PRAGMA cipher_compatibility = 4;');
    };

    final executor = token == null
        ? NativeDatabase(dbFile, setup: setup)
        : NativeDatabase.createInBackground(
            dbFile,
            isolateSetup: () => _driftIsolateSetup(token),
            setup: setup,
          );

    final store = MainStore(executor);

    try {
      await store.customSelect('SELECT 1;').getSingle();
      return store;
    } catch (_) {
      await store.close();
      rethrow;
    }
  }

  Future<StoreInfoDto> _createStoreMetadata({
    required MainStore store,
    required CreateStoreDto dto,
    required String masterPassword,
  }) async {
    final passwordSalt = _generateSecureToken();
    final passwordHash = _hashPassword(masterPassword, passwordSalt);
    final attachmentKey = _generateSecureToken();

    await store.storeMetaDao.createStoreMeta(
      name: dto.name,
      description: dto.description,
      passwordHash: passwordHash,
      salt: passwordSalt,
      attachmentKey: attachmentKey,
    );

    final meta = await store.storeMetaDao.getStoreMeta();
    if (meta == null) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.recordNotFound,
        message: 'Метаданные созданного хранилища не найдены',
        timestamp: DateTime.now(),
      );
    }

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

  Failure<S, AppError> handleError<S extends Object>({
    required String message,
    required Object error,
    required StackTrace stackTrace,
    required String tag,
  }) {
    logError(message, error: error, stackTrace: stackTrace, tag: tag);

    if (error is AppError) {
      return Failure<S, AppError>(error);
    }

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

  void _applyCipher(Database database, DBCipher cipher) {
    final initialResult = database.select('PRAGMA cipher;');
    if (initialResult.isEmpty) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.encryptionFailed,
        message: 'SQLite3 Multiple Ciphers недоступен',
        timestamp: DateTime.now(),
      );
    }

    final requestedCipherName = cipher.name;
    database.execute("PRAGMA cipher = '$requestedCipherName';");

    final appliedResult = database.select('PRAGMA cipher;');
    final appliedCipher = appliedResult.isNotEmpty
        ? appliedResult.first.columnAt(0)?.toString().trim().toLowerCase()
        : null;

    if (appliedCipher != requestedCipherName) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.encryptionFailed,
        message: 'Не удалось применить алгоритм шифрования базы данных',
        data: {
          'requestedCipher': requestedCipherName,
          'appliedCipher': appliedCipher,
        },
        timestamp: DateTime.now(),
      );
    }
  }

  void _applyPragmaKey(Database database, String masterPassword) {
    final escaped = masterPassword.replaceAll("'", "''");
    database.execute("PRAGMA key = '$escaped';");
  }

  void _registerSqlFunctions(Database database) {
    database.createFunction(
      functionName: 'exp',
      argumentCount: const AllowedArgumentCount(1),
      deterministic: true,
      directOnly: true,
      function: (args) {
        if (args.isEmpty || args[0] == null) {
          return 1.0;
        }

        try {
          final value = (args[0] as num).toDouble();
          if (value > 100) {
            return double.infinity;
          }
          if (value < -100) {
            return 0.0;
          }

          final result = math.exp(value);
          if (result.isInfinite || result.isNaN) {
            return 1.0;
          }

          return result;
        } catch (_) {
          return 1.0;
        }
      },
    );
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha512.convert(bytes).toString();
  }

  String _generateSecureToken() {
    return base64UrlEncode(_generateSecureRandomBytes(32));
  }

  Uint8List _generateSecureRandomBytes(int count) {
    final random = math.Random.secure();
    return Uint8List.fromList(
      List<int>.generate(count, (_) => random.nextInt(256)),
    );
  }

  static Future<void> _driftIsolateSetup(RootIsolateToken token) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
}
