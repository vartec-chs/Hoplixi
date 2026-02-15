import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/core/app_preferences/app_storage_service.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/logger/rust_log_bridge.dart';
import 'package:hoplixi/core/providers/launch_db_path_provider.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/run_sub_window_entry.dart';
import 'package:hoplixi/rust/frb_generated.dart';
import 'package:hoplixi/setup_error_handling.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:universal_platform/universal_platform.dart';

import 'app.dart';
import 'di_init.dart';

Future<void> _handleLostData() async {
  final ImagePicker picker = ImagePicker();
  final LostDataResponse response = await picker.retrieveLostData();
  if (response.isEmpty) {
    return;
  }
  final List<XFile>? files = response.files;
  if (files != null) {
    for (final XFile file in files) {
      logInfo('Retrieved lost file: ${file.path}');
    }
  } else {
    logError('Lost data exception: ${response.exception}');
  }
}

Future<void> main(List<String> args) async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. '
      'Please use a different platform.',
    );
  }

  await _runGuardedApp(args);
}

Future<bool> _handleSubWindowStartup() async {
  if (!UniversalPlatform.isDesktop) {
    return false;
  }

  try {
    final bool isSubWindow = await tryRunAsSubWindow();
    if (isSubWindow) {
      return true;
    }
  } catch (_) {
    // Не суб-окно — продолжаем стандартную инициализацию
  }

  return false;
}

String? _parseLaunchFilePath(List<String> args) {
  if (args.isEmpty) {
    return null;
  }

  return args.first;
}

Future<void> _runGuardedApp(List<String> args) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final bool isSubWindow = await _handleSubWindowStartup();
    if (isSubWindow) {
      return;
    }

    final String? filePath = _parseLaunchFilePath(args);

    await _runGuiMode(filePath);
  }, _handleUncaughtError);
}

Future<void> _runGuiMode(String? filePath) async {
  _configureSingleInstanceFocusHandler();

  final singleInstance = FlutterSingleInstance();
  final bool firstInstance = await singleInstance.isFirstInstance();
  if (!firstInstance) {
    try {
      final focusError = await singleInstance.focus(
        _buildFocusMetadata(filePath),
      );
      if (focusError != null) {
        logWarning(
          'Не удалось сфокусировать запущенный экземпляр: $focusError',
        );
      }
    } catch (error, stackTrace) {
      logError(
        'Ошибка при фокусировке запущенного экземпляра',
        error: error,
        stackTrace: stackTrace,
      );
    }
    exit(0);
  }

  await WindowManager.initialize();

  await RustLib.init();
  await dotenv.load(fileName: '.env');

  await AppLogger.instance.initialize(
    config: const LoggerConfig(
      maxFileSize: 10 * 1024 * 1024,
      maxFileCount: 10,
      bufferSize: 50,
      bufferFlushInterval: Duration(seconds: 15),
      enableDebug: true,
      enableInfo: true,
      enableWarning: true,
      enableError: true,
      enableTrace: MainConstants.isProduction ? false : true,
      enableFatal: true,
      enableConsoleOutput: true,
      enableFileOutput: true,
      enableCrashReports: true,
      maxCrashReportCount: 10,
      maxCrashReportFileSize: 10 * 1024 * 1024,
      crashReportRetentionPeriod: Duration(days: 30),
    ),
  );

  await RustLogBridge.instance.initialize();

  setupErrorHandling();

  if (UniversalPlatform.isAndroid) {
    await _handleLostData();
  }

  await setupDI();
  await _syncLaunchAtStartupPreference();
  if (UniversalPlatform.isDesktop) {
    await setupTray();
  }

  logInfo('Starting app with file path: $filePath');

  final app = ProviderScope(
    observers: [LoggingProviderObserver()],
    child: setupToastificationWrapper(App(filePath: filePath)),
  );

  runApp(app);
}

Map<String, dynamic> _buildFocusMetadata(String? filePath) {
  final metadata = <String, dynamic>{};
  final normalized = filePath?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    metadata['filePath'] = normalized;
  }
  return metadata;
}

String? _extractIncomingFilePath(Map<String, dynamic> metadata) {
  final rawFilePath = metadata['filePath'];
  if (rawFilePath is! String) {
    return null;
  }

  final normalized = rawFilePath.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return normalized;
}

void _configureSingleInstanceFocusHandler() {
  FlutterSingleInstance.onFocus = (metadata) async {
    if (UniversalPlatform.isDesktop) {
      await WindowManager.show();
    }

    final filePath = _extractIncomingFilePath(metadata);
    if (filePath == null) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      logWarning(
        'Не удалось обработать путь запуска: контекст навигатора недоступен',
      );
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    container.read(launchDbPathProvider.notifier).setPath(filePath);
    logInfo('Получен путь файла из второго экземпляра: $filePath');
  };
}

Future<void> _syncLaunchAtStartupPreference() async {
  if (!UniversalPlatform.isDesktop) {
    return;
  }

  try {
    final appStorageService = getIt<AppStorageService>();
    final launchAtStartupService = getIt<LaunchAtStartupService>();

    await launchAtStartupService.setup();
    final systemEnabled = await launchAtStartupService.isEnabled();

    final hasStoredValue = await appStorageService.containsKey(
      AppKeys.launchAtStartupEnabled,
    );

    if (!hasStoredValue) {
      await appStorageService.setBool(
        AppKeys.launchAtStartupEnabled,
        systemEnabled,
      );
      return;
    }

    final desiredValue = await appStorageService.getOrDefault(
      AppKeys.launchAtStartupEnabled,
      false,
    );

    if (desiredValue != systemEnabled) {
      await launchAtStartupService.setEnabled(desiredValue);
    }
  } catch (error, stackTrace) {
    logError(
      'Не удалось синхронизировать настройку автозапуска',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

void _handleUncaughtError(Object error, StackTrace stackTrace) {
  logCrash(
    message: 'Uncaught error',
    error: error,
    stackTrace: stackTrace,
    errorType: 'UncaughtError',
  );
  try {
    Toaster.error(title: 'Глобальная ошибка', description: error.toString());
  } catch (_) {
    // ignore toast errors when handling crash
  }
}

Widget setupToastificationWrapper(Widget app) {
  return ToastificationWrapper(
    config: ToastificationConfig(
      maxTitleLines: 2,
      clipBehavior: Clip.hardEdge,
      maxDescriptionLines: 5,
      maxToastLimit: 3,
      itemWidth: UniversalPlatform.isDesktop ? 400 : double.infinity,
      alignment: UniversalPlatform.isDesktop
          ? Alignment.bottomRight
          : Alignment.topCenter,
      marginBuilder: (context, alignment) {
        if (UniversalPlatform.isDesktop) {
          return const EdgeInsets.only(right: 8, bottom: 28);
        } else {
          return const EdgeInsets.only(top: 12, left: 12, right: 12);
        }
      },
    ),
    child: app,
  );
}
