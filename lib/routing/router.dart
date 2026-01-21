import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/setup/providers/setup_completed_provider.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/router_refresh_provider.dart';
import 'package:hoplixi/routing/routes.dart';
import 'package:hoplixi/shared/widgets/desktop_shell.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to the RouterRefreshNotifier to trigger refreshes
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider.notifier);

  final router = GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorKey,

    observers: [LoggingRouteObserver(), RootOverlayObserver.instance],
    refreshListenable: refreshNotifier,
    routes: UniversalPlatform.isDesktop
        ? [
            ShellRoute(
              builder: (context, state, child) => DesktopShell(child: child),
              routes: appRoutes,
            ),
          ]
        : appRoutes,

    redirect: (context, state) async {
      final currentPath = state.matchedLocation;

      // Проверяем, завершена ли первоначальная настройка
      final setupCompletedAsync = await ref.read(
        setupCompletedNotifierProvider.future,
      );
      final setupCompleted = setupCompletedAsync;

      // Если на корневом пути - редиректим в зависимости от состояния setup
      if (currentPath == '/') {
        return setupCompleted ? AppRoutesPaths.home : AppRoutesPaths.setup;
      }

      // Если настройка не завершена и мы не на экране setup — редирект
      if (!setupCompleted && currentPath != AppRoutesPaths.setup) {
        return AppRoutesPaths.setup;
      }

      // Если настройка завершена, но мы на экране setup — редирект на home
      if (setupCompleted && currentPath == AppRoutesPaths.setup) {
        return AppRoutesPaths.home;
      }

      final dbStateAsync = ref.read(mainStoreProvider);

      // Редирект на dashboard если БД открыта и пользователь на пути создания/открытия БД
      if (dbStateAsync.hasValue) {
        final dbState = dbStateAsync.value!;

        // Если БД заблокирована, редиректим на экран блокировки
        if (dbState.isLocked) {
          if (currentPath != AppRoutesPaths.lockStore) {
            WindowManager.instance.setSize(MainConstants.defaultWindowSize);
            WindowManager.instance.center();
            return AppRoutesPaths.lockStore;
          }
          return null;
        }

        if (dbState.isOpen &&
            (currentPath == AppRoutesPaths.createStore ||
                currentPath == AppRoutesPaths.openStore ||
                currentPath == AppRoutesPaths.home ||
                currentPath == AppRoutesPaths.lockStore)) {
          WindowManager.instance.setSize(MainConstants.defaultDashboardSize);
          WindowManager.instance.center();
          return AppRoutesPaths.dashboard;
        } else if ((dbState.isClosed || dbState.isIdle) &&
            (currentPath.startsWith(AppRoutesPaths.dashboard) ||
                currentPath == AppRoutesPaths.lockStore)) {
          WindowManager.instance.setSize(MainConstants.defaultWindowSize);
          WindowManager.instance.center();
          return AppRoutesPaths.home;
        }
      }
      return null;
    },
  );

  router.routerDelegate.addListener(() {
    final loc = router.state.path;
    logTrace('Router location changed: $loc');
    if (loc == AppRoutesPaths.home) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(titlebarStateProvider.notifier)
            .setBackgroundTransparent(false);
      });
    }
  });

  ref.onDispose(() {
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});
