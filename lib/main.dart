import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
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

Future<void> main() async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. Please use a different platform.',
    );
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: ".env");

      await AppLogger.instance.initialize(
        config: const LoggerConfig(
          maxFileSize: 10 * 1024 * 1024, // 10MB
          maxFileCount: 10,
          bufferSize: 50,
          bufferFlushInterval: Duration(seconds: 15),
          enableDebug: true,
          enableInfo: true,
          enableWarning: true,
          enableError: true,
          enableTrace: MainConstants.isProduction
              ? false
              : true, // Disable trace logs in production
          enableFatal: true,
          enableConsoleOutput: true,
          enableFileOutput: true,
          enableCrashReports: true,
          // Crash report settings
          maxCrashReportCount: 10,
          maxCrashReportFileSize: 10 * 1024 * 1024, // 10MB
          crashReportRetentionPeriod: Duration(days: 30),
        ),
      );

      setupErrorHandling();
      // Handle lost data from image_picker on Android
      if (UniversalPlatform.isAndroid) {
        await _handleLostData();
      }
      await WindowManager.initialize();
      await setupDI();
      await setupTray();

      final app = ProviderScope(
        observers: [LoggingProviderObserver()],
        child: setupToastificationWrapper(const App()),
      );

      runApp(app);
    },
    (error, stackTrace) {
      logCrash(
        message: 'Uncaught error',
        error: error,
        stackTrace: stackTrace,
        errorType: 'UncaughtError',
      );
      Toaster.error(title: 'Глобальная ошибка', description: error.toString());
    },
  );
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
          return EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 12,
            right: 12,
          );
        }
      },
    ),
    child: app,
  );
}
