import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/old/models/db_ciphers.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqlite3/sqlite3.dart';

/// Сервис создания SQLite3 Multiple Ciphers-подключения для MainStore.
class MainStoreConnectionService {
  static const String _logTag = 'MainStoreConnectionService';

  AsyncResultDart<MainStore, AppError> createDatabaseConnection(
    String dbFilePath,
    String pragmaKey, {
    DBCipher cipher = DBCipher.chacha20,
    bool isDatabaseCreation = false,
  }) async {
    try {
      logInfo('Creating database connection', tag: _logTag);
      final token = RootIsolateToken.instance!;

      final executor = NativeDatabase.createInBackground(
        File(dbFilePath),
        isolateSetup: () => _driftIsolateSetup(token),
        setup: (rawDb) {
          if (!_debugCheckHasCipher(
            rawDb,
            cipher,
            isDatabaseCreation: isDatabaseCreation,
          )) {
            throw UnsupportedError(
              'This database needs to run with SQLite3 Multiple Ciphers, but that library is '
              'not available!',
            );
          }

          rawDb.config.doubleQuotedStringLiterals = false;

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

          if (pragmaKey.startsWith("x'")) {
            rawDb.execute('PRAGMA key = "$pragmaKey";');
          } else {
            final escaped = pragmaKey.replaceAll("'", "''");
            rawDb.execute("PRAGMA key = '$escaped';");
          }

          rawDb.execute('PRAGMA cipher_compatibility = 4;');
        },
      );

      final database = MainStore(executor);

      try {
        await database.customSelect('SELECT 1;').getSingle();
        logInfo('Database connection established', tag: _logTag);
      } catch (e) {
        await database.close();
        logWarning(
          'Failed to verify database connection',
          tag: _logTag,
          data: {'error': e.toString()},
        );
        return Failure(
          AppError.mainDatabase(
            code: MainDatabaseErrorCode.invalidPassword,
            message: 'Неверный пароль или поврежденная база данных (error: $e)',
            cause: e,
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(database);
    } catch (e, stackTrace) {
      logError(
        'Failed to create database connection',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return Failure(
        AppError.mainDatabase(
          code: MainDatabaseErrorCode.connectionFailed,
          message: 'Не удалось подключиться к базе данных: $e',
          cause: e,
          stackTrace: stackTrace,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  static bool _debugCheckHasCipher(
    Database database,
    DBCipher requestedCipher, {
    required bool isDatabaseCreation,
  }) {
    try {
      final initialResult = database.select('PRAGMA cipher;');
      if (initialResult.isEmpty) {
        return false;
      }

      final currentCipherRaw = initialResult.first.columnAt(0)?.toString();
      final currentCipher = currentCipherRaw?.trim().toLowerCase();
      final requestedCipherName = requestedCipher.name;

      if (currentCipher != null && currentCipher.isNotEmpty) {
        final cipherDescription =
            dbCipherDescriptions[currentCipher] ?? 'Unknown cipher';
        logInfo(
          'Current connection cipher before apply: $currentCipher ($cipherDescription)',
          tag: _logTag,
        );
      } else {
        logInfo(
          'Current connection cipher before apply: not set',
          tag: _logTag,
        );
      }

      if (currentCipher == requestedCipherName) {
        return true;
      }

      // PRAGMA cipher переключает алгоритм для текущего подключения,
      // не выполняя миграцию данных, поэтому его безопасно применить до PRAGMA key.
      database.execute("PRAGMA cipher = '$requestedCipherName';");
      final requestedDescription =
          dbCipherDescriptions[requestedCipherName] ?? 'Unknown cipher';
      if (isDatabaseCreation) {
        logInfo(
          'Database cipher was set to $requestedCipherName ($requestedDescription) for creation.',
          tag: _logTag,
        );
      } else {
        logInfo(
          'Applied requested cipher for opening connection: $requestedCipherName ($requestedDescription).',
          tag: _logTag,
        );
      }

      final appliedResult = database.select('PRAGMA cipher;');
      final appliedCipher = appliedResult.isNotEmpty
          ? appliedResult.first.columnAt(0)?.toString().trim().toLowerCase()
          : null;

      if (appliedCipher != requestedCipherName) {
        logWarning(
          'Requested cipher was not applied',
          tag: _logTag,
          data: {
            'requestedCipher': requestedCipherName,
            'appliedCipher': appliedCipher ?? 'unknown',
          },
        );
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      logError(
        'Failed to check or set cipher',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return false;
    }
  }

  static Future<void> _driftIsolateSetup(RootIsolateToken token) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
}
