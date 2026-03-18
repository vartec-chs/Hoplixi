import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/db_errors.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqlite3/sqlite3.dart';

/// Сервис создания SQLite3 Multiple Ciphers-подключения для MainStore.
class MainStoreConnectionService {
  static const String _logTag = 'MainStoreConnectionService';

  AsyncResultDart<MainStore, DatabaseError> createDatabaseConnection(
    String dbFilePath,
    String pragmaKey,
  ) async {
    try {
      logInfo('Creating database connection', tag: _logTag);
      final token = RootIsolateToken.instance!;

      final executor = NativeDatabase.createInBackground(
        File(dbFilePath),
        isolateSetup: () => _driftIsolateSetup(token),
        setup: (rawDb) {
          if (!_debugCheckHasCipher(rawDb)) {
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
        logError('Failed to verify database connection: $e', tag: _logTag);
        return Failure(
          DatabaseError.invalidPassword(
            message: 'Неверный пароль или поврежденная база данных (error: $e)',
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

  static bool _debugCheckHasCipher(Database database) {
    return database.select('PRAGMA cipher;').isNotEmpty;
  }

  static Future<void> _driftIsolateSetup(RootIsolateToken token) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
}
