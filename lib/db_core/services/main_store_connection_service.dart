import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/models/db_ciphers.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqlite3/sqlite3.dart';

/// Сервис создания SQLite3 Multiple Ciphers-подключения для MainStore.
class MainStoreConnectionService {
  static const String _logTag = 'MainStoreConnectionService';

  AsyncResultDart<MainStore, DatabaseError> createDatabaseConnection(
    String dbFilePath,
    String pragmaKey, {
    DBCipher cipher = DBCipher.chacha20,
    bool isDatabaseCreation = false,
  }) async {
    try {
      debugPrint('[$_logTag] Creating database connection');
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
        debugPrint('[$_logTag] Database connection established');
      } catch (e) {
        await database.close();
        debugPrint('[$_logTag] Failed to verify database connection: $e');
        return Failure(
          DatabaseError.invalidPassword(
            message: 'Неверный пароль или поврежденная база данных (error: $e)',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Success(database);
    } catch (e, stackTrace) {
      debugPrint('[$_logTag] Failed to create database connection: $e');
      debugPrint('[$_logTag] StackTrace: $stackTrace');
      return Failure(
        DatabaseError.connectionFailed(
          message: 'Не удалось подключиться к базе данных: $e',
          timestamp: DateTime.now(),
          stackTrace: stackTrace,
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
        debugPrint(
          '[$_logTag] Current connection cipher before apply: $currentCipher ($cipherDescription)',
        );
      } else {
        debugPrint(
          '[$_logTag] Current connection cipher before apply: not set',
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
        debugPrint(
          '[$_logTag] Database cipher was set to $requestedCipherName ($requestedDescription) for creation.',
        );
      } else {
        debugPrint(
          '[$_logTag] Applied requested cipher for opening connection: $requestedCipherName ($requestedDescription).',
        );
      }

      final appliedResult = database.select('PRAGMA cipher;');
      final appliedCipher = appliedResult.isNotEmpty
          ? appliedResult.first.columnAt(0)?.toString().trim().toLowerCase()
          : null;

      if (appliedCipher != requestedCipherName) {
        debugPrint(
          '[$_logTag] Requested cipher was not applied. Requested: $requestedCipherName, actual: ${appliedCipher ?? 'unknown'}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[$_logTag] Failed to check or set cipher: $e');
      return false;
    }
  }

  static Future<void> _driftIsolateSetup(RootIsolateToken token) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }
}
