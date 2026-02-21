// lib/logger/logger_config.dart

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class LoggerConfig {
  // File settings
  final int maxFileSize; // bytes
  final int maxFileCount;
  final bool autoCleanup;

  // Buffer settings
  final int bufferSize;
  final Duration bufferFlushInterval;

  // Log levels
  final bool enableDebug;
  final bool enableInfo;
  final bool enableWarning;
  final bool enableError;
  final bool enableTrace;
  final bool enableFatal;
  final bool enableConsoleOutput;
  final bool enableFileOutput;

  // Crash reporting
  final bool enableCrashReports;
  final int maxCrashReportCount;
  final int maxCrashReportFileSize; // bytes
  final Duration crashReportRetentionPeriod;

  const LoggerConfig({
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.maxFileCount = 10,
    this.autoCleanup = true,
    this.bufferSize = 100,
    this.bufferFlushInterval = const Duration(seconds: 30),
    this.enableDebug = true,
    this.enableInfo = true,
    this.enableWarning = true,
    this.enableError = true,
    this.enableTrace = true,
    this.enableFatal = true,
    this.enableConsoleOutput = true,
    this.enableFileOutput = true,
    this.enableCrashReports = true,
    this.maxCrashReportCount = 50,
    this.maxCrashReportFileSize = 5 * 1024 * 1024, // 5MB
    this.crashReportRetentionPeriod = const Duration(days: 30),
  });
}

// lib/logger/device_info.dart

class DeviceInfo {
  final String deviceId;
  final String platform;
  final String platformVersion;
  final String deviceModel;
  final String deviceManufacturer;
  final String appName;
  final String appVersion;
  final String buildNumber;
  final String packageName;
  final Map<String, dynamic> additionalInfo;

  DeviceInfo({
    required this.deviceId,
    required this.platform,
    required this.platformVersion,
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.packageName,
    required this.additionalInfo,
  });

  /// Упрощённая мета-информация для суб-окна.
  ///
  /// Вместо полной [DeviceInfo] записывает только
  /// PID процесса, тип окна и платформу.
  factory DeviceInfo.subWindow({required String windowType}) {
    return DeviceInfo(
      deviceId: 'sub_window_$pid',
      platform: Platform.operatingSystem,
      platformVersion: '',
      deviceModel: '',
      deviceManufacturer: '',
      appName: 'hoplixi_sub_window',
      appVersion: '',
      buildNumber: '',
      packageName: '',
      additionalInfo: {
        'isSubWindow': true,
        'windowType': windowType,
        'pid': pid,
      },
    );
  }

  static Future<DeviceInfo> collect() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String deviceId = '';
    String platform = '';
    String platformVersion = '';
    String deviceModel = '';
    String deviceManufacturer = '';
    Map<String, dynamic> additionalInfo = {};

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id ?? '';
      platform = 'Android';
      platformVersion = androidInfo.version.release ?? '';
      deviceModel = androidInfo.model ?? '';
      deviceManufacturer = androidInfo.manufacturer ?? '';
      additionalInfo = {
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'hardware': androidInfo.hardware,
        'product': androidInfo.product,
        'androidId': androidInfo.id,
        'sdkInt': androidInfo.version.sdkInt,
        'isPhysicalDevice': androidInfo.isPhysicalDevice,
        'systemFeatures': androidInfo.systemFeatures,
      };
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
      platform = 'iOS';
      platformVersion = iosInfo.systemVersion ?? '';
      deviceModel = iosInfo.model ?? '';
      deviceManufacturer = 'Apple';
      additionalInfo = {
        'name': iosInfo.name,
        'systemName': iosInfo.systemName,
        'utsname': {
          'machine': iosInfo.utsname.machine,
          'nodename': iosInfo.utsname.nodename,
          'release': iosInfo.utsname.release,
          'sysname': iosInfo.utsname.sysname,
          'version': iosInfo.utsname.version,
        },
        'isPhysicalDevice': iosInfo.isPhysicalDevice,
      };
    } else if (Platform.isWindows) {
      final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId ?? '';
      platform = 'Windows';
      platformVersion = windowsInfo.displayVersion ?? '';
      deviceModel = windowsInfo.productName ?? '';
      deviceManufacturer = windowsInfo.registeredOwner ?? '';
      additionalInfo = {
        'computerName': windowsInfo.computerName,
        'userName': windowsInfo.userName,
        'majorVersion': windowsInfo.majorVersion,
        'minorVersion': windowsInfo.minorVersion,
        'buildNumber': windowsInfo.buildNumber,
        'platformId': windowsInfo.platformId,
        'csdVersion': windowsInfo.csdVersion,
        'servicePackMajor': windowsInfo.servicePackMajor,
        'servicePackMinor': windowsInfo.servicePackMinor,
        'suitMask': windowsInfo.suitMask,
        'productType': windowsInfo.productType,
        'reserved': windowsInfo.reserved,
        'buildLab': windowsInfo.buildLab,
        'buildLabEx': windowsInfo.buildLabEx,
        'digitalProductId': windowsInfo.digitalProductId,
        'editionId': windowsInfo.editionId,
        'installDate': windowsInfo.installDate.toIso8601String(),
        'productId': windowsInfo.productId,
        'releaseId': windowsInfo.releaseId,
      };
    } else if (Platform.isMacOS) {
      final MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID ?? '';
      platform = 'macOS';
      platformVersion = macInfo.osRelease ?? '';
      deviceModel = macInfo.model ?? '';
      deviceManufacturer = 'Apple';
      additionalInfo = {
        'computerName': macInfo.computerName,
        'hostName': macInfo.hostName,
        'arch': macInfo.arch,
        'kernelVersion': macInfo.kernelVersion,
        'majorVersion': macInfo.majorVersion,
        'minorVersion': macInfo.minorVersion,
        'patchVersion': macInfo.patchVersion,
        'activeCPUs': macInfo.activeCPUs,
        'memorySize': macInfo.memorySize,
        'cpuFrequency': macInfo.cpuFrequency,
      };
    } else if (Platform.isLinux) {
      final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      deviceId = linuxInfo.machineId ?? '';
      platform = 'Linux';
      platformVersion = linuxInfo.version ?? '';
      deviceModel = linuxInfo.prettyName ?? '';
      deviceManufacturer = 'Unknown';
      additionalInfo = {
        'name': linuxInfo.name,
        'version': linuxInfo.version,
        'id': linuxInfo.id,
        'idLike': linuxInfo.idLike,
        'versionCodename': linuxInfo.versionCodename,
        'versionId': linuxInfo.versionId,
        'prettyName': linuxInfo.prettyName,
        'buildId': linuxInfo.buildId,
        'variant': linuxInfo.variant,
        'variantId': linuxInfo.variantId,
      };
    }

    return DeviceInfo(
      deviceId: deviceId,
      platform: platform,
      platformVersion: platformVersion,
      deviceModel: deviceModel,
      deviceManufacturer: deviceManufacturer,
      appName: packageInfo.appName,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      packageName: packageInfo.packageName,
      additionalInfo: additionalInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'platform': platform,
      'platformVersion': platformVersion,
      'deviceModel': deviceModel,
      'deviceManufacturer': deviceManufacturer,
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'packageName': packageName,
      'additionalInfo': additionalInfo,
    };
  }
}

class Session {
  final String id;
  final DateTime startTime;
  final DeviceInfo deviceInfo;

  /// Признак того, что сессия принадлежит суб-окну.
  final bool isSubWindow;

  /// Тип суб-окна (например, `passwordGenerator`).
  /// Заполняется только если [isSubWindow] == `true`.
  final String? windowType;

  DateTime? endTime;

  Session({
    required this.id,
    required this.startTime,
    required this.deviceInfo,
    this.isSubWindow = false,
    this.windowType,
    this.endTime,
  });

  /// Создаёт сессию для главного окна с полной
  /// информацией об устройстве.
  factory Session.create(DeviceInfo deviceInfo) {
    return Session(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      deviceInfo: deviceInfo,
    );
  }

  /// Создаёт сессию для суб-окна с упрощённой
  /// мета-информацией (PID + тип окна).
  factory Session.createSubWindow(String windowType) {
    return Session(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      deviceInfo: DeviceInfo.subWindow(windowType: windowType),
      isSubWindow: true,
      windowType: windowType,
    );
  }

  void end() {
    endTime = DateTime.now();
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'isSubWindow': isSubWindow,
      if (windowType != null) 'windowType': windowType,
      'deviceInfo': deviceInfo.toJson(),
    };
  }
}

// lib/logger/log_entry.dart
enum LogLevel {
  debug('DEBUG'),
  info('INFO'),
  warning('WARNING'),
  error('ERROR'),
  trace('TRACE'),
  fatal('FATAL');

  const LogLevel(this.name);
  final String name;
}

class LogEntry {
  final String sessionId;

  /// PID процесса, создавшего запись.
  ///
  /// Позволяет идентифицировать источник записи
  /// в общем JSONL-файле (главное окно / суб-окно).
  final int processId;

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? additionalData;

  LogEntry({
    required this.sessionId,
    required this.processId,
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'processId': processId,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tag': tag,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'additionalData': _sanitizeAdditionalData(additionalData),
    };
  }

  // Helper method to sanitize additionalData for JSON serialization
  Map<String, dynamic>? _sanitizeAdditionalData(Map<String, dynamic>? data) {
    if (data == null) return null;

    final sanitized = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is DateTime) {
        sanitized[entry.key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        sanitized[entry.key] = _sanitizeAdditionalData(value);
      } else if (value is List) {
        sanitized[entry.key] = _sanitizeList(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }

  // Helper method to sanitize lists
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map<String, dynamic>) {
        return _sanitizeAdditionalData(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name}] ');
    if (tag != null) buffer.write('[$tag] ');
    buffer.write(message);
    if (error != null) {
      buffer.write('\nError: $error');
    }
    if (stackTrace != null) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }
    if (additionalData != null && additionalData!.isNotEmpty) {
      buffer.write('\nAdditional Data: $additionalData');
    }
    return buffer.toString();
  }
}
