import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/theme/theme_window_sync_service.dart';
import 'package:hoplixi/setup_error_handling.dart';
import 'package:window_manager/window_manager.dart';

import 'features/multi_window/screens/auth_window_screen.dart';
import 'features/multi_window/screens/password_generator_screen.dart';
import 'core/multi_window/sub_window_app.dart';
import 'core/multi_window/sub_window_type.dart';
import 'core/multi_window/window_controller_ext.dart';

/// Точка входа суб-окна.
///
/// Вызывается из `main()`, когда процесс запущен
/// как дочернее окно (`desktop_multi_window` передаёт
/// аргументы через [WindowController]).
///
/// Возвращает `true`, если текущий процесс — суб-окно
/// и приложение запущено. `false` — если это главное окно
/// и нужна стандартная инициализация.
Future<bool> tryRunAsSubWindow() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = await WindowController.fromCurrentEngine();
  final raw = controller.arguments;

  // Пустые аргументы — главное окно
  if (raw.isEmpty) return false;

  final args = SubWindowArguments.decode(raw);
  if (args == null) return false;

  // --- Инициализация логирования для суб-окна ---
  // Запись в файл включена, но с упрощённой DeviceInfo
  // (только PID + тип окна) и без краш-репортов.
  await AppLogger.instance.initialize(
    config: const LoggerConfig(
      enableDebug: true,
      enableInfo: true,
      enableWarning: true,
      enableError: true,
      enableTrace: true,
      enableFatal: true,
      enableConsoleOutput: true,
      enableFileOutput: true,
      enableCrashReports: false,
    ),
    isSubWindow: true,
    windowType: args.type.name,
  );

  logInfo('Суб-окно запущено: ${args.type.name}', tag: 'SubWindow');

  // --- Глобальная обработка ошибок (логирование + тосты) ---
  setupErrorHandling();

  // Инициализируем window_manager для суб-окна
  await windowManager.ensureInitialized();

  // Настраиваем размер и заголовок окна
  final windowOptions = WindowOptions(
    size: args.type.size,
    minimumSize: args.type.minSize,
    center: true,
    title: args.type.title,
    titleBarStyle: TitleBarStyle.hidden,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Инициализируем обработчик методов окна
  // для межоконного взаимодействия
  await controller.initWindowMethodHandler(
    onThemeSyncSet: ThemeWindowSyncService.instance.handleIncomingForSub,
  );

  // Определяем содержимое на основе типа
  final Widget content = switch (args.type) {
    SubWindowType.passwordGenerator => const PasswordGeneratorScreen(),
    SubWindowType.auth => AuthWindowScreen(payload: args.payload),
  };

  runApp(
    ProviderScope(
      child: SubWindowApp(type: args.type, child: content),
    ),
  );
  return true;
}
