import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/widgets/app_loading_screen.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_observer.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_provider.dart';
import 'package:hoplixi/shared/widgets/watchers/shortcut_watcher.dart';
import 'package:hoplixi/shared/widgets/watchers/tray_watcher.dart';

import 'root_app_shell.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({
    super.key,
    required this.initialThemeModeFuture,
    required this.router,
    required this.isStoreOpeningOverlayVisible,
  });

  final Future<ThemeMode> initialThemeModeFuture;
  final RouterConfig<Object> router;
  final bool isStoreOpeningOverlayVisible;

  @override
  Widget build(BuildContext context) {
    return ShortcutWatcher(
      child: TrayWatcher(
        child: AppLifecycleObserver(
          child: AppActivityScope(
            child: _AppThemeLoader(
              initialThemeModeFuture: initialThemeModeFuture,
              router: router,
              isStoreOpeningOverlayVisible: isStoreOpeningOverlayVisible,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppThemeLoader extends StatelessWidget {
  const _AppThemeLoader({
    required this.initialThemeModeFuture,
    required this.router,
    required this.isStoreOpeningOverlayVisible,
  });

  final Future<ThemeMode> initialThemeModeFuture;
  final RouterConfig<Object> router;
  final bool isStoreOpeningOverlayVisible;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: initialThemeModeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingScreen();
        }

        final themeMode = snapshot.data!;
        logTrace('App build with theme mode: $themeMode');

        return _ConfiguredMaterialApp(
          router: router,
          themeMode: themeMode,
          isStoreOpeningOverlayVisible: isStoreOpeningOverlayVisible,
        );
      },
    );
  }
}

class _ConfiguredMaterialApp extends StatelessWidget {
  const _ConfiguredMaterialApp({
    required this.router,
    required this.themeMode,
    required this.isStoreOpeningOverlayVisible,
  });

  final RouterConfig<Object> router;
  final ThemeMode themeMode;
  final bool isStoreOpeningOverlayVisible;

  @override
  Widget build(BuildContext context) {
    return animated_theme.ThemeProvider(
      initTheme: themeMode == ThemeMode.light
          ? AppTheme.light(context)
          : AppTheme.dark(context),
      child: MaterialApp.router(
        title: MainConstants.appName,
        routerConfig: router,
        theme: AppTheme.light(context),
        darkTheme: AppTheme.dark(context),
        themeMode: themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return RootAppShell(
            isStoreOpeningOverlayVisible: isStoreOpeningOverlayVisible,
            child: child!,
          );
        },
      ),
    );
  }
}
