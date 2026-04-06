import 'dart:async';

import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/localization/locale_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/launch_db_path_provider.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/theme/theme_window_sync_service.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/cloud_sync_auth_flow_listener.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/cloud_sync_snapshot_sync_listener.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/main_store/provider/decrypted_files_guard_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/router.dart';
import 'package:hoplixi/shared/widgets/app_loading_screen.dart';
import 'package:hoplixi/shared/widgets/desktop_shell.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_observer.dart';
import 'package:hoplixi/shared/widgets/watchers/shortcut_watcher.dart';
import 'package:hoplixi/shared/widgets/watchers/tray_watcher.dart';
import 'package:typed_prefs/typed_prefs.dart';
import 'package:universal_platform/universal_platform.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key, this.filePath});

  final String? filePath;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  ProviderSubscription<AsyncValue<ThemeMode>>? _themeSyncSubscription;
  ProviderSubscription<CurrentStoreSyncManualReauthIssue?>?
  _manualReauthIssueSubscription;
  late final Future<ThemeMode> _initialThemeModeFuture;
  bool _isShowingManualReauthDialog = false;
  String? _handledManualReauthIssueKey;

  @override
  void initState() {
    super.initState();

    _initialThemeModeFuture = () async {
      final storage = getIt.get<PreferencesService>().settingsPrefs;
      final savedMode = await storage.getThemeMode();
      return savedMode;
    }();

    Future<void>(() {
      ref.read(localeProvider.future);
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

    _manualReauthIssueSubscription = ref
        .listenManual<CurrentStoreSyncManualReauthIssue?>(
          currentStoreSyncManualReauthIssueProvider,
          (previous, next) {
            final issueKey = next?.dedupeKey;
            if (issueKey == null) {
              _handledManualReauthIssueKey = null;
              return;
            }

            if (_isShowingManualReauthDialog ||
                _handledManualReauthIssueKey == issueKey) {
              return;
            }

            _handledManualReauthIssueKey = issueKey;
            _isShowingManualReauthDialog = true;

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await _showManualReauthDialog(next!);
              } finally {
                _isShowingManualReauthDialog = false;
              }
            });
          },
          fireImmediately: true,
        );
  }

  @override
  void dispose() {
    _themeSyncSubscription?.close();
    _manualReauthIssueSubscription?.close();
    super.dispose();
  }

  Future<void> _showManualReauthDialog(
    CurrentStoreSyncManualReauthIssue issue,
  ) async {
    final dialogContext =
        navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (dialogContext == null || !mounted) {
      ref.read(currentStoreSyncManualReauthIssueProvider.notifier).clear();
      return;
    }

    final providerName = issue.provider.metadata.displayName;
    final tokenLabel = issue.tokenLabel ?? providerName;
    final action = await showDialog<_ManualReauthDialogAction>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Требуется повторная авторизация Cloud Sync'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: SelectableText(
                [
                  'Токен cloud sync для провайдера $providerName больше не подходит для доступа к облаку.',
                  issue.description ??
                      'Приложение не смогло автоматически обновить авторизацию.',
                  'Текущий токен: $tokenLabel.',
                  'Чтобы продолжить синхронизацию, заново выполните авторизацию вручную. После этого при необходимости переподключите новый токен к текущему хранилищу.',
                ].join('\n\n'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop(_ManualReauthDialogAction.later),
              child: const Text('Позже'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop(_ManualReauthDialogAction.openAuth),
              child: const Text('Авторизовать вручную'),
            ),
          ],
        );
      },
    );

    ref.read(currentStoreSyncManualReauthIssueProvider.notifier).clear();

    if (!mounted || action != _ManualReauthDialogAction.openAuth) {
      return;
    }

    final previousRoute =
        ref.read(routerProvider).state.matchedLocation.isNotEmpty
        ? ref.read(routerProvider).state.matchedLocation
        : AppRoutesPaths.home;

    await showCloudSyncAuthSheet(
      context: dialogContext,
      ref: ref,
      previousRoute: previousRoute,
      initialProvider: issue.provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return ShortcutWatcher(
      child: TrayWatcher(
        child: AppLifecycleObserver(
          child: FutureBuilder<ThemeMode>(
            future: _initialThemeModeFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const AppLoadingScreen();
              }

              final themeMode = snapshot.data!;

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
                  // locale: activeLocale,
                  locale: TranslationProvider.of(
                    context,
                  ).flutterLocale, // use provider

                  supportedLocales: AppLocaleUtils.supportedLocales,
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) {
                    return CloudSyncSnapshotSyncListener(
                      child: CloudSyncAuthFlowListener(
                        child: animated_theme.ThemeSwitchingArea(
                          child: UniversalPlatform.isDesktop
                              ? RootBarsOverlay(child: child!)
                              : child!,
                        ),
                      ),
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

enum _ManualReauthDialogAction { later, openAuth }
