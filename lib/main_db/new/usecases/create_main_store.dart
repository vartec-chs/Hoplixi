import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/logger/models.dart' as logger_models;
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/models/store_key_config.dart';
import 'package:hoplixi/main_db/new/services/db_key_derivation_service.dart';
import 'package:hoplixi/main_db/new/services/main_store_connection_service.dart';
import 'package:hoplixi/main_db/new/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/main_db/new/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart';

typedef Session = ({
  MainStore store,
  StoreInfoDto info,
  String storeDirectoryPath,
});

class CreateMainStore {
  static const String _logTag = 'CreateMainStore';

  static const String attachmentsFolder = 'attachments';
  static const String decryptedAttachmentsFolder = 'attachments_decrypted';

  final MainStoreConnectionService _connectionService;
  final DbKeyDerivationService _keyService;

  CreateMainStore({
    MainStoreConnectionService? connectionService,
    DbKeyDerivationService? keyService,
  }) : _connectionService = connectionService ?? MainStoreConnectionService(),
       _keyService =
           keyService ?? DbKeyDerivationService(getIt<FlutterSecureStorage>());

  AsyncResultDart<Session, AppError> call({
    required CreateStoreDto dto,
    required String masterPassword,
  }) async {
    MainStore? store;
    Directory? createdStorageDir;

    try {
      final storagePath = await resolveBaseStoragePath(dto);
      final storageDirPath = await resolveStorageDirectoryPath(dto);
      final normalizedName = normalizeStorageName(dto.name);
      final storageDir = Directory(storageDirPath);

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

      final argon2Salt = DbKeyDerivationService.generateSalt();
      final keyConfig = StoreKeyConfig(
        argon2Salt: argon2Salt,
        useDeviceKey: dto.useDeviceKey,
        cipher: dto.cipher,
      );
      logInfo(
        'Prepared store manifest key config (useDeviceKey=${dto.useDeviceKey}, cipher=${dto.cipher.name})',
        tag: _logTag,
      );

      final pragmaKey = await _keyService.derivePragmaKey(
        masterPassword,
        argon2Salt,
        useDeviceKey: dto.useDeviceKey,
      );

      final storeResult = await _connectionService.createDatabaseConnection(
        dbFilePath,
        pragmaKey,
        cipher: dto.cipher,
        isDatabaseCreation: true,
      );
      if (storeResult.isError()) {
        throw storeResult.exceptionOrNull()!;
      }

      store = storeResult.getOrThrow();

      final info = await _createStoreMetadata(
        store: store,
        dto: dto,
        masterPassword: masterPassword,
      );

      await _writeStoreManifest(
        storagePath: storageDir.path,
        info: info,
        keyConfig: keyConfig,
      );

      logInfo('Store created successfully: ${dto.name}', tag: _logTag);
      return Success((
        store: store,
        info: info,
        storeDirectoryPath: storageDir.path,
      ));
    } catch (error, stackTrace) {
      await store?.close();
      await _cleanupCreatedStorage(createdStorageDir);

      return _handleError(
        message: 'Failed to create store',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  String getAttachmentsPath(String storePath) {
    return p.join(storePath, attachmentsFolder);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return p.join(storePath, decryptedAttachmentsFolder);
  }

  Future<bool> storageDirectoryExists(String path) {
    return Directory(path).exists();
  }

  Future<void> deleteStorageDirectory(String path) async {
    await Directory(path).delete(recursive: true);
  }

  Future<String> resolveBaseStoragePath(CreateStoreDto dto) async {
    return dto.path.trim().isEmpty ? AppPaths.appStoragesPath : dto.path.trim();
  }

  Future<String> resolveStorageDirectoryPath(CreateStoreDto dto) async {
    final storagePath = await resolveBaseStoragePath(dto);
    return p.join(storagePath, normalizeStorageName(dto.name));
  }

  String normalizeStorageName(String name) {
    var normalized = name.trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

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
    } catch (error, stackTrace) {
      logError(
        'Failed to find database file',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
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

  Future<void> _cleanupCreatedStorage(Directory? createdStorageDir) async {
    if (createdStorageDir == null) {
      return;
    }

    try {
      await deleteStorageDirectory(createdStorageDir.path);
    } catch (error, stackTrace) {
      logWarning(
        'Failed to clean up storage directory after createStore error',
        tag: _logTag,
        data: {'error': error.toString(), 'stackTrace': stackTrace.toString()},
      );
    }
  }

  Future<void> _writeStoreManifest({
    required String storagePath,
    required StoreInfoDto info,
    required StoreKeyConfig keyConfig,
  }) async {
    final deviceInfo = await logger_models.DeviceInfo.collect();
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion =
        packageInfo.version +
        (packageInfo.buildNumber.isNotEmpty
            ? '+${packageInfo.buildNumber}'
            : '');
    final lastModifiedBy = StoreManifestLastModifiedBy(
      deviceId: deviceInfo.deviceId,
      clientInstanceId: '${deviceInfo.deviceId}:${packageInfo.packageName}',
      appVersion: appVersion,
    );

    final manifest = StoreManifest.initial(
      lastMigrationVersion: MainConstants.databaseSchemaVersion,
      appVersion: appVersion,
      storeUuid: info.id,
      storeName: info.name,
      updatedAt: info.modifiedAt.toUtc(),
      lastModifiedBy: lastModifiedBy,
      keyConfig: keyConfig,
    );

    try {
      await StoreManifestService.writeTo(storagePath, manifest);
      logInfo('Wrote store_manifest.json', tag: _logTag);
    } catch (error, stackTrace) {
      throw AppError.mainDatabase(
        code: MainDatabaseErrorCode.queryFailed,
        message: 'Не удалось записать store_manifest.json: $error',
        cause: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      );
    }
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
}

Failure<S, AppError> _handleError<S extends Object>({
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
