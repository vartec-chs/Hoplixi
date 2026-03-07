import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as path;

/// Результат очистки краш-репортов
class CrashCleanupResult {
  /// Количество удаленных файлов по причине превышения лимита
  final int deletedByCount;

  /// Количество удаленных файлов по причине превышения размера
  final int deletedBySize;

  /// Количество удаленных файлов по причине истечения срока хранения
  final int deletedByAge;

  const CrashCleanupResult({
    required this.deletedByCount,
    required this.deletedBySize,
    required this.deletedByAge,
  });

  /// Общее количество удаленных файлов
  int get totalDeleted => deletedByCount + deletedBySize + deletedByAge;

  @override
  String toString() {
    return 'CrashCleanupResult(deletedByCount: $deletedByCount, '
        'deletedBySize: $deletedBySize, deletedByAge: $deletedByAge, '
        'totalDeleted: $totalDeleted)';
  }
}

/// Модель краш-репорта
class CrashReport {
  final String id;
  final DateTime timestamp;
  final String message;
  final String? errorType;
  final String error;
  final String stackTrace;
  final DeviceInfo deviceInfo;
  final Map<String, dynamic>? additionalData;

  CrashReport({
    required this.id,
    required this.timestamp,
    required this.message,
    this.errorType,
    required this.error,
    required this.stackTrace,
    required this.deviceInfo,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'errorType': errorType,
      'error': error,
      'stackTrace': stackTrace,
      'deviceInfo': deviceInfo.toJson(),
      'additionalData': additionalData,
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      errorType: json['errorType'] as String?,
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String,
      deviceInfo: DeviceInfo(
        deviceId: json['deviceInfo']['deviceId'] as String,
        platform: json['deviceInfo']['platform'] as String,
        platformVersion: json['deviceInfo']['platformVersion'] as String,
        deviceModel: json['deviceInfo']['deviceModel'] as String,
        deviceManufacturer: json['deviceInfo']['deviceManufacturer'] as String,
        appName: json['deviceInfo']['appName'] as String,
        appVersion: json['deviceInfo']['appVersion'] as String,
        buildNumber: json['deviceInfo']['buildNumber'] as String,
        packageName: json['deviceInfo']['packageName'] as String,
        additionalInfo:
            json['deviceInfo']['additionalInfo'] as Map<String, dynamic>,
      ),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
}

/// Конфигурация менеджера краш-репортов
class CrashReportConfig {
  /// Максимальное количество краш-репортов
  final int maxCount;

  /// Максимальный размер файла краш-репорта в байтах
  final int maxFileSize;

  /// Период хранения краш-репортов
  final Duration retentionPeriod;

  /// Автоматическая очистка при инициализации
  final bool autoCleanup;

  const CrashReportConfig({
    this.maxCount = 50,
    this.maxFileSize = 5 * 1024 * 1024, // 5MB
    this.retentionPeriod = const Duration(days: 30),
    this.autoCleanup = true,
  });
}

/// Менеджер краш-репортов
class CrashReportManager {
  static CrashReportManager? _instance;
  static CrashReportManager get instance =>
      _instance ??= CrashReportManager._();

  CrashReportManager._();

  late Directory _crashDirectory;
  late DeviceInfo _deviceInfo;
  late CrashReportConfig _config;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  CrashReportConfig get config => _config;

  /// Инициализация менеджера краш-репортов
  Future<void> initialize(
    DeviceInfo deviceInfo, {
    CrashReportConfig config = const CrashReportConfig(),
  }) async {
    if (_initialized) return;

    _deviceInfo = deviceInfo;
    _config = config;
    _crashDirectory = Directory(await AppPaths.appCrashReportsPath);

    if (!await _crashDirectory.exists()) {
      await _crashDirectory.create(recursive: true);
    }

    // Автоматическая очистка при инициализации
    if (_config.autoCleanup) {
      await cleanupOldReports();
    }

    _initialized = true;
  }

  /// Генерация уникального имени файла для краш-репорта
  String _generateFileName() {
    final now = DateTime.now();
    final dateTimeStr = DateFormat('yyyy-MM-dd_HH-mm-ss-SSS').format(now);
    return 'crash_$dateTimeStr.jsonl';
  }

  /// Запись краш-репорта
  Future<File?> writeCrashReport({
    required String message,
    required dynamic error,
    required StackTrace stackTrace,
    String? errorType,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_initialized) {
      return null;
    }

    try {
      final crashReport = CrashReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        message: message,
        errorType: errorType ?? error.runtimeType.toString(),
        error: error.toString(),
        stackTrace: stackTrace.toString(),
        deviceInfo: _deviceInfo,
        additionalData: additionalData,
      );

      final fileName = _generateFileName();
      final file = File(path.join(_crashDirectory.path, fileName));

      final jsonStr = jsonEncode(crashReport.toJson());
      await file.writeAsString('$jsonStr\n', mode: FileMode.write);

      return file;
    } catch (e) {
      // Не логируем ошибку записи краш-репорта, чтобы избежать рекурсии
      return null;
    }
  }

  /// Получение списка всех краш-репортов
  Future<List<File>> getCrashReportFiles() async {
    if (!_initialized) return [];

    try {
      if (!await _crashDirectory.exists()) {
        return [];
      }

      return _crashDirectory
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.jsonl'))
          .cast<File>()
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      return [];
    }
  }

  /// Чтение краш-репорта из файла
  Future<CrashReport?> readCrashReport(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.trim().split('\n');
      if (lines.isEmpty) return null;

      final json = jsonDecode(lines.first) as Map<String, dynamic>;
      return CrashReport.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Удаление краш-репорта
  Future<bool> deleteCrashReport(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Очистка старых краш-репортов
  ///
  /// Удаляет файлы по следующим критериям:
  /// 1. Превышение максимального количества файлов
  /// 2. Превышение максимального размера файла
  /// 3. Истечение срока хранения
  Future<CrashCleanupResult> cleanupOldReports() async {
    if (!_initialized) {
      return const CrashCleanupResult(
        deletedByCount: 0,
        deletedBySize: 0,
        deletedByAge: 0,
      );
    }

    int deletedByCount = 0;
    int deletedBySize = 0;
    int deletedByAge = 0;

    try {
      final files = await getCrashReportFiles();
      final now = DateTime.now();
      final retentionCutoff = now.subtract(_config.retentionPeriod);

      // Список файлов для удаления
      final filesToDelete = <File>[];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];

        try {
          final stat = await file.stat();

          // Критерий 1: Превышение количества файлов
          if (i >= _config.maxCount) {
            filesToDelete.add(file);
            deletedByCount++;
            continue;
          }

          // Критерий 2: Превышение размера файла
          if (stat.size > _config.maxFileSize) {
            filesToDelete.add(file);
            deletedBySize++;
            continue;
          }

          // Критерий 3: Истечение срока хранения
          if (stat.modified.isBefore(retentionCutoff)) {
            filesToDelete.add(file);
            deletedByAge++;
            continue;
          }
        } catch (e) {
          // Если не удается получить статистику файла, пропускаем
          continue;
        }
      }

      // Удаляем файлы
      for (final file in filesToDelete) {
        try {
          await file.delete();
        } catch (e) {
          // Игнорируем ошибки удаления отдельных файлов
        }
      }
    } catch (e) {
      // Игнорируем общие ошибки очистки
    }

    return CrashCleanupResult(
      deletedByCount: deletedByCount,
      deletedBySize: deletedBySize,
      deletedByAge: deletedByAge,
    );
  }

  /// Принудительная очистка всех краш-репортов
  Future<int> clearAllReports() async {
    if (!_initialized) return 0;

    int deletedCount = 0;
    try {
      final files = await getCrashReportFiles();
      for (final file in files) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          // Игнорируем ошибки удаления
        }
      }
    } catch (e) {
      // Игнорируем ошибки
    }
    return deletedCount;
  }

  /// Получение общего размера всех краш-репортов в байтах
  Future<int> getTotalSize() async {
    if (!_initialized) return 0;

    int totalSize = 0;
    try {
      final files = await getCrashReportFiles();
      for (final file in files) {
        try {
          final stat = await file.stat();
          totalSize += stat.size;
        } catch (e) {
          // Игнорируем ошибки
        }
      }
    } catch (e) {
      // Игнорируем ошибки
    }
    return totalSize;
  }

  /// Получение количества краш-репортов
  Future<int> getCrashReportCount() async {
    final files = await getCrashReportFiles();
    return files.length;
  }
}

/// Функция для записи краш-репорта (удобный хелпер)
Future<File?> writeCrashReport({
  required String message,
  required dynamic error,
  required StackTrace stackTrace,
  String? errorType,
  Map<String, dynamic>? additionalData,
}) async {
  return CrashReportManager.instance.writeCrashReport(
    message: message,
    error: error,
    stackTrace: stackTrace,
    errorType: errorType,
    additionalData: additionalData,
  );
}
