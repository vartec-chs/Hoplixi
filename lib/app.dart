import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/lifecycle/app_lifecycle_observer.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/routing/router.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:hoplixi/shared/widgets/desktop_shell.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:universal_platform/universal_platform.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key, this.filePath});

  final String? filePath;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with TrayListener {
  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    await WindowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    // trayManager.popUpContextMenu();
    // do something
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == null) {
      logWarning('Tray menu item clicked with null key', tag: 'TrayManager');
      return;
    }
    final menuItemKey = AppTrayMenuItemKeyExtension.fromKey(menuItem.key!);
    if (menuItemKey == null) {
      logWarning(
        'Unknown tray menu item key: ${menuItem.key}',
        tag: 'TrayManager',
      );
      return;
    }
    switch (menuItemKey) {
      case AppTrayMenuItemKey.showWindow:
        await WindowManager.show();
        break;
      case AppTrayMenuItemKey.exitApp:
        await WindowManager.close();
        break;
      case AppTrayMenuItemKey.pathLauncher:
        logInfo(
          'Path Launcher clicked, file path: ${widget.filePath}',
          tag: 'TrayManager',
        );
        break;
    }
    super.onTrayMenuItemClick(menuItem);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final theme = ref.read(themeProvider);

    final themeMode = theme.value ?? ThemeMode.system;

    return AppLifecycleObserver(
      child: animated_theme.ThemeProvider(
        initTheme: themeMode == ThemeMode.light
            ? AppTheme.light(context)
            : themeMode == ThemeMode.dark
            ? AppTheme.dark(context)
            : MediaQuery.of(context).platformBrightness == Brightness.dark
            ? AppTheme.dark(context)
            : AppTheme.light(context),
        child: MaterialApp.router(
          title: MainConstants.appName,
          routerConfig: router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return animated_theme.ThemeSwitchingArea(
              child: UniversalPlatform.isDesktop
                  ? RootBarsOverlay(child: child!)
                  : child!,
            );
          },
        ),
      ),
    );
  }
}
