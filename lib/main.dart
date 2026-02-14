import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/logger/rust_log_bridge.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/run_sub_window_entry.dart';
import 'package:hoplixi/rust/frb_generated.dart';
import 'package:hoplixi/setup_error_handling.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:universal_platform/universal_platform.dart';

import 'app.dart';
import 'di_init.dart';

final ArgParser _parser = ArgParser()
  ..addOption(
    'file',
    abbr: 'f',
    mandatory: false,
    help: 'Path to the file to open',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help for flags');

class _LaunchOptions {
  const _LaunchOptions({required this.filePath, required this.isCliMode});

  final String? filePath;
  final bool isCliMode;
}

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

_LaunchOptions _parseLaunchOptions(List<String> args) {
  ArgResults results;
  try {
    results = _parser.parse(args);
  } catch (error) {
    stderr.writeln(error.toString());
    exit(1);
  }

  if (results['help'] == true) {
    stdout.writeln(_parser.usage);
    exit(0);
  }

  String? filePath = results['file'] as String?;
  if (filePath == null && args.isNotEmpty && !args.first.startsWith('-')) {
    filePath = args.first;
  }

  final List<String> flags = args.where((a) => a.startsWith('-')).toList();
  final bool onlyFileFlag =
      flags.isNotEmpty && flags.every((f) => f == '--file' || f == '-f');
  final bool isCliMode = flags.isNotEmpty && !onlyFileFlag;

  return _LaunchOptions(filePath: filePath, isCliMode: isCliMode);
}

Future<void> _runGuardedApp(List<String> args) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final bool isSubWindow = await _handleSubWindowStartup();
    if (isSubWindow) {
      return;
    }

    final _LaunchOptions launchOptions = _parseLaunchOptions(args);

    final String? filePath = launchOptions.filePath;
    final bool isCliMode = launchOptions.isCliMode;

    if (Platform.isWindows && isCliMode) {
      await _runCliMode(filePath);
      return;
    }

    await _runGuiMode(filePath);
  }, _handleUncaughtError);
}

Future<void> _runCliMode(String? filePath) async {
  if (filePath != null) {
    stdout.writeln('File path: $filePath');
  } else {
    stdout.writeln('No file path provided');
  }
  exit(0);
}

Future<void> _runGuiMode(String? filePath) async {
  await WindowManager.initialize();

  final bool firstInstance = await FlutterSingleInstance().isFirstInstance();
  if (!firstInstance) {
    try {
      await WindowManager.focus();
    } catch (_) {
      // ignore focus failures
    }
    exit(0);
  }

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
  if (UniversalPlatform.isDesktop) {
    await setupTray();
  }

  final app = ProviderScope(
    observers: [LoggingProviderObserver()],
    child: setupToastificationWrapper(App(filePath: filePath)),
  );

  runApp(app);
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
