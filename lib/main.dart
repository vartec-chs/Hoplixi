import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/setup_error_handling.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:hoplixi/src/rust/frb_generated.dart';
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
      'Web platform is not supported in this version. Please use a different platform.',
    );
  }

  // --- Parse args early (before heavy init) ---
  final ArgParser parser = ArgParser()
    ..addOption(
      'file',
      abbr: 'f',
      mandatory: false,
      help: 'Path to the file to open',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help for flags');

  ArgResults results;
  try {
    results = parser.parse(args);
    if (results['help'] == true) {
      // Show usage and treat as CLI
      stdout.writeln(parser.usage);
      // Use CommandlineOrGuiWindows to ensure console attachment on Windows if needed
      if (Platform.isWindows) {
        // run minimal CLI mode via package so console output is visible
        CommandlineOrGuiWindows.runAppCommandlineOrGUI(
          argsCount: args.length,
          closeOnCompleteCommandlineOptionOnly: true,
          commandlineRun: () async {
            // Already printed usage above, keep process alive briefly if needed
            // then exit
            // Note: package will close process if configured so
          },
          gui: const SizedBox.shrink(),
        );
      }
      exit(0);
    }
  } catch (err) {
    stderr.writeln(err.toString());
    exit(1);
  }

  // Determine file path:
  String? filePath = results['file'] as String?;
  if (filePath == null && args.isNotEmpty && !args.first.startsWith('-')) {
    // positional single argument -> likely file open via Explorer
    filePath = args.first;
  }

  // Decide whether this invocation is CLI-mode or GUI-mode.
  // Heuristic:
  // - If there are any flags except --file/-f -> treat as CLI
  // - If only a positional single path or only --file flag -> treat as GUI (open file)
  final List<String> flags = args.where((a) => a.startsWith('-')).toList();
  final bool onlyFileFlag =
      flags.isNotEmpty && flags.every((f) => f == '--file' || f == '-f');
  final bool isCliMode = flags.isNotEmpty && !onlyFileFlag;

  // Run guarded zone for crash logging
  runZonedGuarded(
    () async {
      // --- CLI mode: use plugin to attach console and run minimal CLI without heavy init ---
      if (Platform.isWindows && isCliMode) {
        CommandlineOrGuiWindows.runAppCommandlineOrGUI(
          argsCount: args.length, // non-zero -> CLI mode in the plugin
          closeOnCompleteCommandlineOptionOnly:
              true, // close after CLI completes in production-like flow
          commandlineRun: () async {
            // Implement your CLI actions here.
            // Keep this minimal: do not initialize UI, DI, DB, etc.
            if (filePath != null) {
              stdout.writeln('File path: $filePath');
            } else {
              stdout.writeln('No file path provided');
            }
            // Add other CLI flags handling if needed (export, version, etc.)
          },
          gui: const SizedBox.shrink(),
        );
        // plugin will either exit or keep process according to closeOnComplete...,
        // but we return from main after the call.
        return;
      }

      // --- GUI mode: first-instance check BEFORE heavy init ---
      final bool firstInstance = await FlutterSingleInstance()
          .isFirstInstance();
      if (!firstInstance) {
        // App already running: focus existing window and exit.
        // (Optional) implement IPC to send filePath to primary instance.
        try {
          await WindowManager.focus();
        } catch (_) {
          // ignore focus failures
        }
        // If you have IPC to send filePath to the running instance, call it here.
        exit(0);
      }

      // --- Now safe to perform heavy initialization for GUI ---
      await RustLib.init();
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env');

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
          enableTrace: MainConstants.isProduction ? false : true,
          enableFatal: true,
          enableConsoleOutput: true,
          enableFileOutput: true,
          enableCrashReports: true,
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
        child: setupToastificationWrapper(App(filePath: filePath)),
      );

      // --- On Windows use commandline_or_gui_windows to allow console attachment for debug CLI runs,
      //     but pass argsCount = 0 so it doesn't interpret this as CLI mode (we already decided GUI) ---
      if (Platform.isWindows) {
        CommandlineOrGuiWindows.runAppCommandlineOrGUI(
          argsCount:
              0, // zero => plugin will not enter commandline mode and will run GUI normally
          closeOnCompleteCommandlineOptionOnly: false,
          commandlineRun: () async {
            // won't be called because argsCount == 0
          },
          gui: app,
        );
      } else {
        // Non-windows: just run the app
        runApp(app);
      }
    },
    (error, stackTrace) {
      // Global error handling
      logCrash(
        message: 'Uncaught error',
        error: error,
        stackTrace: stackTrace,
        errorType: 'UncaughtError',
      );
      try {
        Toaster.error(
          title: 'Глобальная ошибка',
          description: error.toString(),
        );
      } catch (_) {
        // ignore toast errors when handling crash
      }
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
          return const EdgeInsets.only(top: 12, left: 12, right: 12);
        }
      },
    ),
    child: app,
  );
}
