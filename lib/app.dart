import 'dart:async';

import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/localization/locale_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/launch_db_path_provider.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/theme/theme_window_sync_service.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/main_store/provider/decrypted_files_guard_provider.dart';
import 'package:hoplixi/routing/router.dart';
import 'package:hoplixi/shared/widgets/app_loading_screen.dart';
import 'package:hoplixi/shared/widgets/desktop_shell.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_observer.dart';
import 'package:hoplixi/shared/widgets/watchers/shortcut_watcher.dart';
import 'package:hoplixi/shared/widgets/watchers/tray_watcher.dart';
import 'package:universal_platform/universal_platform.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key, this.filePath});

  final String? filePath;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  ProviderSubscription<AsyncValue<ThemeMode>>? _themeSyncSubscription;
  late final Future<ThemeMode> _initialThemeModeFuture;
  late final Future<List<dynamic>> _initialThemeAndLocaleFuture;

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  void initState() {
    super.initState();

    _initialThemeModeFuture = () async {
      final storage = getIt.get<AppStorageService>();
      final savedMode = await storage.get(AppKeys.themeMode);
      return _parseThemeMode(savedMode);
    }();

    _initialThemeAndLocaleFuture = Future.wait<dynamic>([
      _initialThemeModeFuture,
      ref.read(localeProvider.future),
    ]);

    Future<void>(() {
      ref.read(launchDbPathProvider.notifier).setPath(widget.filePath);
      ref.read(decryptedFilesGuardProvider);
    });

    unawaited(
      ThemeWindowSyncService.instance.bindMainNotifier(
        ref.read(themeProvider.notifier),
      ),
    );

    _themeSyncSubscription = ref.listenManual<AsyncValue<ThemeMode>>(
      themeProvider,
      (previous, next) {
        final mode = next.value;
        if (mode == null) return;
        if (ThemeWindowSyncService.instance.consumeSuppressedOutboundFlag(
          mode,
        )) {
          return;
        }
        unawaited(ThemeWindowSyncService.instance.broadcastFromMain(mode));
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _themeSyncSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final localeAsync = ref.watch(localeProvider);

    return ShortcutWatcher(
      child: TrayWatcher(
        child: AppLifecycleObserver(
          child: FutureBuilder<List<dynamic>>(
            future: _initialThemeAndLocaleFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const AppLoadingScreen();
              }

              final themeMode = snapshot.data![0] as ThemeMode;
              final initialLocale = snapshot.data![1] as Locale;
              final activeLocale = localeAsync.value ?? initialLocale;

              logTrace('App build with theme mode: $themeMode');
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
                  locale: activeLocale,
                  supportedLocales: const [
                    Locale('en'), // English
                    Locale('ru'), // Russian
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
              );
            },
          ),
        ),
      ),
    );
  }
}
