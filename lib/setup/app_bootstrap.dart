import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:hoplixi/app/app.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/logger/rust_log_bridge.dart';
import 'package:hoplixi/core/providers/launch_db_path_provider.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/rust/frb_generated.dart';
import 'package:hoplixi/setup/app_launch_context.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/setup/run_sub_window_entry.dart';
import 'package:hoplixi/setup/setup_error_handling.dart';
import 'package:hoplixi/setup/setup_tray.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:typed_prefs/typed_prefs.dart';
import 'package:universal_platform/universal_platform.dart';

Future<void> runGuardedApp(List<String> args) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final isSubWindow = await _handleSubWindowStartup();
    if (isSubWindow) {
      return;
    }

    final launchContext = parseLaunchContext(args);
    await _runGuiMode(launchContext);
  }, _handleUncaughtError);
}

Future<void> _runGuiMode(LaunchContext launchContext) async {
  if (UniversalPlatform.isDesktop) {
    _configureSingleInstanceFocusHandler();

    final singleInstance = FlutterSingleInstance();
    final firstInstance = await singleInstance.isFirstInstance();
    if (!firstInstance) {
      try {
        final focusError = await singleInstance.focus(
          buildFocusMetadata(launchContext.filePath),
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
  }

  await WindowManager.initialize(showOnInit: !launchContext.startInTray);

  try {
    debugPrint('Initializing Rust library...');
    await RustLib.init();
    debugPrint('Rust library initialized successfully');
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

    debugPrint('Initializing Rust log bridge...');
    await RustLogBridge.instance.initialize();
    debugPrint('Rust log bridge initialized successfully');

    setupErrorHandling();

    if (UniversalPlatform.isAndroid) {
      await _handleLostData();
    }

    await setupDI();
    await _applyInstallConfig();
    await _syncLaunchAtStartupPreference();
    if (UniversalPlatform.isDesktop) {
      await setupTray();
    }

    if (launchContext.startInTray) {
      logInfo('Приложение запущено в режиме автозапуска: старт в трей');
    }
    logInfo('Starting app with file path: ${launchContext.filePath}');

    final app = ProviderScope(
      observers: [LoggingProviderObserver()],
      child: TranslationProvider(
        child: setupToastificationWrapper(
          App(filePath: launchContext.filePath),
        ),
      ),
    );

    runApp(app);
  } catch (error, stackTrace) {
    debugPrint('Fatal initialization error: $error\n$stackTrace');
    runApp(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _handleLostData() async {
  final picker = ImagePicker();
  final response = await picker.retrieveLostData();
  if (response.isEmpty) {
    return;
  }

  final files = response.files;
  if (files != null) {
    for (final file in files) {
      logInfo('Retrieved lost file: ${file.path}');
    }
  } else {
    logError('Lost data exception: ${response.exception}');
  }
}

Future<bool> _handleSubWindowStartup() async {
  if (!UniversalPlatform.isDesktop) {
    return false;
  }

  try {
    final isSubWindow = await tryRunAsSubWindow();
    if (isSubWindow) {
      return true;
    }
  } catch (_) {
    // Не суб-окно — продолжаем стандартную инициализацию
  }

  return false;
}

void _configureSingleInstanceFocusHandler() {
  FlutterSingleInstance.onFocus = (metadata) async {
    if (UniversalPlatform.isDesktop) {
      await WindowManager.show();
    }

    final filePath = extractIncomingFilePath(metadata);
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

Future<void> _applyInstallConfig() async {
  if (!UniversalPlatform.isDesktop) {
    return;
  }

  try {
    await InstallConfigService.applyIfPresent(
      storage: getIt<PreferencesService>(),
      launchAtStartupService: getIt<LaunchAtStartupService>(),
    );
  } catch (error, stackTrace) {
    logError(
      'Ошибка при применении конфигурации установщика',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _syncLaunchAtStartupPreference() async {
  if (!UniversalPlatform.isDesktop) {
    return;
  }

  try {
    final store = getIt<PreferencesService>().settingsPrefs;
    final launchAtStartupService = getIt<LaunchAtStartupService>();

    await launchAtStartupService.setup();
    final systemEnabled = await launchAtStartupService.isEnabled();

    final hasStoredValue = await store.launchAtStartupEnabled.get() != null;

    if (!hasStoredValue) {
      await store.setLaunchAtStartupEnabled(systemEnabled);
      return;
    }

    final desiredValue = await store.getLaunchAtStartupEnabled();

    final appliedValue = await launchAtStartupService.setEnabled(desiredValue);
    if (appliedValue != desiredValue) {
      logWarning('Не удалось применить состояние автозапуска');
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
