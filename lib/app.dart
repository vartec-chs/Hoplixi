import 'dart:async';

import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/theme/theme_window_sync_service.dart';
import 'package:hoplixi/main_store/provider/decrypted_files_guard_provider.dart';
import 'package:hoplixi/routing/router.dart';
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

  @override
  void initState() {
    super.initState();

    Future<void>(() {
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
    final theme = ref.read(themeProvider);

    final themeMode = theme.value ?? ThemeMode.system;

    return ShortcutWatcher(
      child: TrayWatcher(
        child: AppLifecycleObserver(
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
              theme: AppTheme.light(context),
              darkTheme: AppTheme.dark(context),
              themeMode: themeMode,
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
        ),
      ),
    );
  }
}
