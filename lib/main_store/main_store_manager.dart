import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:file_crypto/file_crypto.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:hoplixi/main_store/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

Future<void> setupSqlCipher() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
}

/// Менеджер для управления хранилищами MainStore
///
/// Отвечает за создание, открытие, закрытие и управление
/// зашифрованными хранилищами паролей на основе Drift + SQLCipher
class MainStoreManager {
  static const String _logTag = 'MainStoreManager';
  static const String _dbExtension = MainConstants.dbExtension;
  static const String _attachmentsFolder = 'attachments';
  static const String _decryptedAttachmentsFolder = 'attachments_decrypted';

  final DatabaseHistoryService _dbHistoryService;
  final _uuid = const Uuid();

  MainStore? _currentStore;
  String? _currentStorePath;

  MainStoreManager(this._dbHistoryService);

  /// Проверка, открыто ли хранилище
  bool get isStoreOpen => _currentStore != null && _currentStorePath != null;

  /// Получить текущий путь к хранилищу
  String? get currentStorePath => _currentStorePath;

  MainStore? get currentStore => _currentStore;

  /// Создать новое хранилище
  ///
  /// [dto] - данные для создания хранилища
  /// Возвращает информацию о созданном хранилище или ошибку
  AsyncResultDart<StoreInfoDto, DatabaseError> createStore(
    CreateStoreDto dto,
  ) async {
    try {
      logInfo('Creating new store: ${dto.name}', tag: _logTag);

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        return Failure(
          DatabaseError.alreadyInitialized(
            message:
                'Хранилище уже открыто. Закройте текущее перед созданием нового.',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Нормализация имени папки
      late final String normalizedName;
      try {
        normalizedName = _normalizeStorageName(dto.name);
      } on DatabaseError catch (e) {
        return Failure(e);
      }

      final storagePath = await AppPaths.appStoragePath;
      final storageDir = Directory(p.join(storagePath, normalizedName));

      // Проверка существования папки
      if (await storageDir.exists()) {
        return Failure(
          DatabaseError.validationError(
            message: 'Хранилище с таким именем уже существует',
            data: {'path': storageDir.path},
            timestamp: DateTime.now(),
          ),
        );
      }

      // Создание папки хранилища
      await storageDir.create(recursive: true);
      logInfo('Created storage directory: ${storageDir.path}', tag: _logTag);

      // Создание подпапки attachments
      final attachmentsDir = Directory(
        p.join(storageDir.path, _attachmentsFolder),
      );
      await attachmentsDir.create(recursive: true);
      logInfo('Created attachments directory', tag: _logTag);

      // Генерация соли и хеширование пароля
      final salt = _uuid.v4();
      final passwordHash = _hashPassword(dto.password, salt);

      // Генерация криптографически безопасного случайного ключа для шифрования attachments
      final attachmentKey = _generateSecureKey();

      // Путь к файлу БД
      final dbFilePath = _getDbFilePath(storageDir.path, normalizedName);

      // Создание соединения с БД
      final dbResult = await _createDatabaseConnection(
        dbFilePath,
        dto.password,
      );

      if (dbResult.isError()) {
        // Удаляем созданную папку при ошибке
        await storageDir.delete(recursive: true);
        return dbResult.fold(
          (_) => Success(
            StoreInfoDto(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              version: '',
            ),
          ),
          (error) => Failure(error),
        );
      }

      final database = dbResult.getOrThrow();
      _currentStore = database;
      _currentStorePath = storageDir.path;

      // Создание записи метаданных в БД
      final storeId = _uuid.v4();
      await database
          .into(database.storeMetaTable)
          .insert(
            StoreMetaTableCompanion.insert(
              id: Value(storeId),
              name: dto.name,
              description: Value(dto.description),
              passwordHash: passwordHash,
              salt: salt,
              attachmentKey: attachmentKey,
              version: const Value('1.0.0'),
            ),
          );

      logInfo('Created store metadata with id: $storeId', tag: _logTag);

      // Добавление в историю
      await _dbHistoryService.create(
        path: storageDir.path,
        dbId: storeId,
        name: dto.name,
        description: dto.description,
        password: dto.saveMasterPassword ? dto.password : null,
        savePassword: dto.saveMasterPassword,
      );

      logInfo('Store created successfully: ${dto.name}', tag: _logTag);

      // Получение информации о созданном хранилище
      return getStoreInfo();
    } catch (e, stackTrace) {
      logError(
        'Failed to create store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось создать хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Открыть существующее хранилище
  ///
  /// [dto] - данные для открытия хранилища
  /// Возвращает информацию о хранилище или ошибку
  AsyncResultDart<StoreInfoDto, DatabaseError> openStore(
    OpenStoreDto dto,
  ) async {
    try {
      logInfo('Opening store at: ${dto.path}', tag: _logTag);

      // Проверка, открыто ли уже хранилище
      if (isStoreOpen) {
        await _currentStore?.close();
        _currentStore = null;
        _currentStorePath = null;
      }

      // Проверка существования директории или файла БД
      final storageDir = Directory(dto.path);
      final dbFile = File(dto.path);

      String actualStoragePath = dto.path;

      if (await storageDir.exists()) {
        actualStoragePath = dto.path;
      } else if (await dbFile.exists() && dto.path.endsWith(_dbExtension)) {
        // Если это файл БД, получить путь к директории
        actualStoragePath = p.dirname(dto.path);
      } else {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Директория хранилища или файл БД не найдены',
            data: {'path': dto.path},
            timestamp: DateTime.now(),
          ),
        );
      }

      // Поиск файла БД
      final dbFilePath = await _findDatabaseFile(actualStoragePath);
      if (dbFilePath == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Файл базы данных не найден в директории',
            data: {'path': actualStoragePath},
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Found database file: $dbFilePath', tag: _logTag);

      // Создание соединения с БД
      final dbResult = await _createDatabaseConnection(
        dbFilePath,
        dto.password,
      );

      if (dbResult.isError()) {
        return dbResult.fold(
          (_) => Success(
            StoreInfoDto(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              version: '',
            ),
          ),
          (error) => Failure(error),
        );
      }

      final database = dbResult.getOrThrow();

      // Проверка пароля и получение метаданных
      final verifyResult = await _verifyPassword(database, dto.password);
      if (verifyResult.isError()) {
        await database.close();
        return verifyResult.fold(
          (_) => Success(
            StoreInfoDto(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              lastOpenedAt: DateTime.now(),
              version: '',
            ),
          ),
          (error) => Failure(error),
        );
      }

      final storeMeta = verifyResult.getOrThrow();

      _currentStore = database;
      _currentStorePath = actualStoragePath;

      // Обновление времени последнего доступа
      await database
          .update(database.storeMetaTable)
          .replace(storeMeta.copyWith(lastOpenedAt: DateTime.now()));

      // Обновление или создание записи в истории
      final existingHistory = await _dbHistoryService.getByPath(
        actualStoragePath,
      );
      if (existingHistory == null) {
        // Создаем новую запись в истории, если ее нет
        await _dbHistoryService.create(
          path: actualStoragePath,
          dbId: storeMeta.id,
          name: storeMeta.name,
          description: storeMeta.description,
          password: dto.saveMasterPassword ? dto.password : null,
          savePassword: dto.saveMasterPassword,
        );
        logInfo('Created new history entry for opened store', tag: _logTag);
      } else {
        // Обновляем время последнего доступа для существующей записи
        await _dbHistoryService.updateLastAccessed(actualStoragePath);
        logInfo('Updated existing history entry', tag: _logTag);
      }

      logInfo('Store opened successfully', tag: _logTag);

      return getStoreInfo();
    } catch (e, stackTrace) {
      logError(
        'Failed to open store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.connectionFailed(
          message: 'Не удалось открыть хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Закрыть текущее хранилище
  AsyncResultDart<Unit, DatabaseError> closeStore() async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Closing store', tag: _logTag);

      await _currentStore?.close();
      _currentStore = null;
      _currentStorePath = null;

      logInfo('Store closed successfully', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to close store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось закрыть хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить информацию о текущем хранилище
  AsyncResultDart<StoreInfoDto, DatabaseError> getStoreInfo() async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final query = _currentStore!.select(_currentStore!.storeMetaTable);
      final meta = await query.getSingleOrNull();

      if (meta == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      final dto = StoreInfoDto(
        id: meta.id,
        name: meta.name,
        description: meta.description,
        createdAt: meta.createdAt,
        modifiedAt: meta.modifiedAt,
        lastOpenedAt: meta.lastOpenedAt,
        version: meta.version,
      );

      return Success(dto);
    } catch (e, stackTrace) {
      logError(
        'Failed to get store info: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.queryFailed(
          message: 'Не удалось получить информацию о хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Обновить метаданные хранилища
  AsyncResultDart<StoreInfoDto, DatabaseError> updateStore(
    UpdateStoreDto dto,
  ) async {
    try {
      if (!isStoreOpen) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Updating store metadata', tag: _logTag);

      final query = _currentStore!.select(_currentStore!.storeMetaTable);
      final currentMeta = await query.getSingleOrNull();

      if (currentMeta == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Подготовка обновлений
      var updatedMeta = currentMeta.copyWith(modifiedAt: DateTime.now());

      if (dto.name != null) {
        updatedMeta = updatedMeta.copyWith(name: dto.name);
      }

      if (dto.description != null) {
        updatedMeta = updatedMeta.copyWith(description: Value(dto.description));
      }

      // Обновление пароля, если указано
      if (dto.password != null) {
        final newSalt = _uuid.v4();
        final newPasswordHash = _hashPassword(dto.password!, newSalt);
        updatedMeta = updatedMeta.copyWith(
          passwordHash: newPasswordHash,
          salt: newSalt,
        );
        logInfo('Password updated for store', tag: _logTag);
      }

      // Сохранение изменений
      await _currentStore!
          .update(_currentStore!.storeMetaTable)
          .replace(updatedMeta);

      // Обновление в истории
      if (_currentStorePath != null) {
        final historyEntry = await _dbHistoryService.getByPath(
          _currentStorePath!,
        );
        if (historyEntry != null) {
          await _dbHistoryService.update(
            historyEntry.copyWith(
              name: dto.name ?? historyEntry.name,
              description: dto.description ?? historyEntry.description,
              password: dto.saveMasterPassword == true && dto.password != null
                  ? dto.password
                  : dto.saveMasterPassword == false
                  ? null
                  : historyEntry.password,
              savePassword: dto.saveMasterPassword ?? historyEntry.savePassword,
            ),
          );
        }
      }

      logInfo('Store metadata updated successfully', tag: _logTag);

      return getStoreInfo();
    } catch (e, stackTrace) {
      logError(
        'Failed to update store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.updateFailed(
          message: 'Не удалось обновить хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Удалить хранилище
  ///
  /// [path] - путь к директории хранилища
  /// [deleteFromDisk] - удалить файлы с диска (по умолчанию true)
  AsyncResultDart<Unit, DatabaseError> deleteStore(
    String path, {
    bool deleteFromDisk = true,
  }) async {
    try {
      logInfo('Deleting store at: $path', tag: _logTag);

      // Закрыть, если это текущее хранилище
      if (_currentStorePath == path && isStoreOpen) {
        await closeStore();
      }

      // Удаление из истории
      await _dbHistoryService.deleteByPath(path);

      // Удаление с диска
      if (deleteFromDisk) {
        final storageDir = Directory(path);
        if (await storageDir.exists()) {
          await storageDir.delete(recursive: true);
          logInfo('Store deleted from disk', tag: _logTag);
        }
      }

      logInfo('Store deleted successfully', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete store: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.deleteFailed(
          message: 'Не удалось удалить хранилище: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Удалить хранилище только из истории
  ///
  /// Файлы хранилища на диске остаются нетронутыми
  /// [path] - путь к директории хранилища
  AsyncResultDart<Unit, DatabaseError> deleteStoreFromHistory(
    String path,
  ) async {
    try {
      logInfo('Deleting store from history: $path', tag: _logTag);

      // Удаление из истории
      await _dbHistoryService.deleteByPath(path);

      logInfo('Store removed from history successfully', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete store from history: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.deleteFailed(
          message: 'Не удалось удалить хранилище из истории: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Удалить файлы хранилища с диска
  ///
  /// Запись в истории остается нетронутой
  /// [path] - путь к директории хранилища
  AsyncResultDart<Unit, DatabaseError> deleteStoreFromDisk(String path) async {
    try {
      logInfo('Deleting store files from disk: $path', tag: _logTag);

      // Закрыть, если это текущее хранилище
      if (_currentStorePath == path && isStoreOpen) {
        await closeStore();
      }

      // Удаление с диска
      final storageDir = Directory(path);
      if (await storageDir.exists()) {
        await storageDir.delete(recursive: true);
        logInfo('Store files deleted from disk', tag: _logTag);
      } else {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Директория хранилища не найдена',
            data: {'path': path},
            timestamp: DateTime.now(),
          ),
        );
      }

      logInfo('Store files deleted successfully', tag: _logTag);

      return const Success(unit);
    } catch (e, stackTrace) {
      logError(
        'Failed to delete store files from disk: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.deleteFailed(
          message: 'Не удалось удалить файлы хранилища с диска: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Создать подпапку в текущем хранилище
  ///
  /// [folderName] - имя подпапки
  /// Возвращает полный путь к созданной папке
  AsyncResultDart<String, DatabaseError> createSubfolder(
    String folderName,
  ) async {
    try {
      if (!isStoreOpen || _currentStorePath == null) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      late final String normalizedName;
      try {
        normalizedName = _normalizeStorageName(folderName);
      } on DatabaseError catch (e) {
        return Failure(e);
      }

      final subfolderPath = p.join(_currentStorePath!, normalizedName);
      final subfolder = Directory(subfolderPath);

      if (await subfolder.exists()) {
        return Failure(
          DatabaseError.validationError(
            message: 'Папка с таким именем уже существует',
            data: {'path': subfolderPath},
            timestamp: DateTime.now(),
          ),
        );
      }

      await subfolder.create(recursive: true);
      logInfo('Created subfolder: $normalizedName', tag: _logTag);

      return Success(subfolderPath);
    } catch (e, stackTrace) {
      logError(
        'Failed to create subfolder: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось создать подпапку: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Получить путь к папке вложений
  AsyncResultDart<String, DatabaseError> getAttachmentsPath() async {
    try {
      if (!isStoreOpen || _currentStorePath == null) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final attachmentsPath = p.join(_currentStorePath!, _attachmentsFolder);
      return Success(attachmentsPath);
    } catch (e) {
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось получить путь к вложениям: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Получить путь к папке вложений расшифрованного файла
  AsyncResultDart<String, DatabaseError>
  getDecryptedAttachmentsDirPath() async {
    try {
      if (!isStoreOpen || _currentStorePath == null) {
        return Failure(
          DatabaseError.notInitialized(
            message: 'Хранилище не открыто',
            timestamp: DateTime.now(),
          ),
        );
      }

      final decryptedAttachmentsPath = p.join(
        _currentStorePath!,
        _decryptedAttachmentsFolder,
      );
      return Success(decryptedAttachmentsPath);
    } catch (e) {
      return Failure(
        DatabaseError.unknown(
          message: 'Не удалось получить путь к расшифрованным вложениям: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // === Приватные методы ===

  /// Нормализовать имя папки хранилища
  ///
  /// Выбрасывает [DatabaseError.validationError] если имя пустое после нормализации
  String _normalizeStorageName(String name) {
    // Удаляем лишние пробелы по краям
    var normalized = name.trim();

    // Заменяем пробелы на подчеркивания
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');

    // Удаляем недопустимые символы для файловой системы
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    // Если имя пустое после нормализации, выбрасываем ошибку
    if (normalized.isEmpty) {
      throw DatabaseError.validationError(
        message: 'Имя хранилища содержит только недопустимые символы',
        data: {'originalName': name},
        timestamp: DateTime.now(),
      );
    }

    return normalized;
  }

  /// Получить путь к файлу БД
  String _getDbFilePath(String storagePath, String storageName) {
    return p.join(storagePath, '$storageName$_dbExtension');
  }

  /// Найти файл БД в директории
  Future<String?> _findDatabaseFile(String storagePath) async {
    try {
      final dir = Directory(storagePath);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith(_dbExtension)) {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      logError('Failed to find database file: $e', tag: _logTag);
      return null;
    }
  }

  /// Создать соединение с БД с шифрованием
  AsyncResultDart<MainStore, DatabaseError> _createDatabaseConnection(
    String dbFilePath,
    String password,
  ) async {
    try {
      logInfo('Creating database connection', tag: _logTag);
      final token = RootIsolateToken.instance!;

      final executor = NativeDatabase.createInBackground(
        File(dbFilePath),
        isolateSetup: () async {
          BackgroundIsolateBinaryMessenger.ensureInitialized(token);
          if (Platform.isAndroid) {
            await setupSqlCipher(); //code from docs
          }
        },
        setup: (rawDb) {
          final result = rawDb.select('pragma cipher_version');
          if (result.isEmpty) {
            throw UnsupportedError(
              'This database needs to run with SQLCipher, but that library is '
              'not available!',
            );
          }
          rawDb.config.doubleQuotedStringLiterals = false;

          // Регистрация функции exp для SQLite для сортировки по времени
          rawDb.createFunction(
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
                // Ограничиваем значение, чтобы избежать overflow
                if (value > 100) {
                  return double.infinity;
                }
                if (value < -100) {
                  return 0.0;
                }
                final result = math.exp(value);
                // Проверка на infinity и NaN
                if (result.isInfinite || result.isNaN) {
                  return 1.0;
                }

                return result;
              } catch (e) {
                return 1.0;
              }
            },
          );
          final escapedPassword = password.replaceAll("'", "''");
          rawDb.execute("PRAGMA key = '$escapedPassword';");
        },
      );

      final database = MainStore(executor);

      // Проверка соединения (попытка выполнить простой запрос)
      try {
        await database.customSelect('SELECT 1').getSingle();
        logInfo('Database connection established', tag: _logTag);
      } catch (e) {
        await database.close();
        logError('Failed to verify database connection: $e', tag: _logTag);
        return Failure(
          DatabaseError.invalidPassword(
            message: 'Неверный пароль или поврежденная база данных',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(database);
    } catch (e, stackTrace) {
      logError(
        'Failed to create database connection: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.connectionFailed(
          message: 'Не удалось подключиться к базе данных: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Проверить пароль и получить метаданные
  AsyncResultDart<StoreMeta, DatabaseError> _verifyPassword(
    MainStore database,
    String password,
  ) async {
    try {
      final query = database.select(database.storeMetaTable);
      final meta = await query.getSingleOrNull();

      if (meta == null) {
        return Failure(
          DatabaseError.recordNotFound(
            message: 'Метаданные хранилища не найдены',
            timestamp: DateTime.now(),
          ),
        );
      }

      // Проверка хеша пароля
      final expectedHash = _hashPassword(password, meta.salt);
      if (expectedHash != meta.passwordHash) {
        return Failure(
          DatabaseError.invalidPassword(
            message: 'Неверный пароль',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(meta);
    } catch (e, stackTrace) {
      logError(
        'Failed to verify password: $e',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        DatabaseError.queryFailed(
          message: 'Не удалось проверить пароль: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Хешировать пароль с солью
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  /// Генерировать криптографически безопасный случайный ключ
  ///
  /// Создает 32-байтовый (256-бит) ключ используя криптографически
  /// безопасный генератор случайных чисел для шифрования attachments
  ///
  /// Возвращает Base64-закодированный ключ
  String _generateSecureKey() {
    final bytes = KeyDerivationService.generateSecureRandomBytes(32);
    return base64Encode(bytes);
  }
}
