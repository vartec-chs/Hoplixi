import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/core/multi_window/multi_window_service.dart';
import 'package:hoplixi/core/multi_window/sub_window_type.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:open_dir/open_dir.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:universal_platform/universal_platform.dart';

enum AppActivityMode { active, tray, exiting }

final initialAppActivityModeProvider = Provider<AppActivityMode>((ref) {
  return AppActivityMode.active;
});

final appActivityModeProvider =
    NotifierProvider<AppActivityModeNotifier, AppActivityMode>(
      AppActivityModeNotifier.new,
    );

final appInTrayProvider = Provider<bool>((ref) {
  return ref.watch(appActivityModeProvider) == AppActivityMode.tray;
});

final trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayService(ref);

  ref.listen(appActivityModeProvider, (previous, next) {
    unawaited(service.syncMenuForMode(next));
  });

  ref.onDispose(service.dispose);
  return service;
});

class AppActivityModeNotifier extends Notifier<AppActivityMode> {
  @override
  AppActivityMode build() {
    return ref.watch(initialAppActivityModeProvider);
  }

  void setActive() {
    state = AppActivityMode.active;
  }

  void setTray() {
    state = AppActivityMode.tray;
  }

  void setExiting() {
    state = AppActivityMode.exiting;
  }
}

enum AppTrayMenuItemKey {
  showWindow('show_window'),
  hideToTray('hide_to_tray'),
  passwordGenerator('password_generator'),
  exitApp('exit_app'),
  pathLauncher('path_launcher');

  final String key;
  const AppTrayMenuItemKey(this.key);
}

extension AppTrayMenuItemKeyExtension on AppTrayMenuItemKey {
  static AppTrayMenuItemKey? fromKey(String key) {
    for (final item in AppTrayMenuItemKey.values) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }
}

class TrayService with TrayListener {
  TrayService(this.ref);

  static const String _logTag = 'TrayService';

  final Ref ref;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || !UniversalPlatform.isDesktop) {
      return;
    }

    trayManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows ? 'assets/logo/logo.ico' : 'assets/logo/logo.png',
    );
    await trayManager.setToolTip('Hoplixi');
    await syncMenuForMode(ref.read(appActivityModeProvider));

    _initialized = true;
    logInfo('Tray service initialized', tag: _logTag);
  }

  Future<void> syncMenuForMode(AppActivityMode mode) async {
    if (!UniversalPlatform.isDesktop) {
      return;
    }

    final isInTray = mode == AppActivityMode.tray;
    final menu = Menu(
      items: [
        MenuItem(
          key: AppTrayMenuItemKey.showWindow.key,
          label: 'Показать окно',
          disabled: !isInTray,
        ),
        MenuItem(
          key: AppTrayMenuItemKey.hideToTray.key,
          label: 'Свернуть в трей',
          disabled: isInTray,
        ),
        MenuItem(
          key: AppTrayMenuItemKey.passwordGenerator.key,
          label: 'Генератор паролей',
        ),
        MenuItem.separator(),
        MenuItem(
          key: AppTrayMenuItemKey.pathLauncher.key,
          label: 'Открыть папку приложения',
        ),
        MenuItem(
          key: AppTrayMenuItemKey.exitApp.key,
          label: 'Выход из приложения',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  Future<void> hideToTray() async {
    if (!UniversalPlatform.isDesktop) {
      return;
    }

    ref.read(appActivityModeProvider.notifier).setTray();
    await WindowManager.hide();
  }

  Future<void> showFromTray() async {
    if (!UniversalPlatform.isDesktop) {
      return;
    }

    ref.read(appActivityModeProvider.notifier).setActive();
    await WindowManager.show();
    await WindowManager.setSize(MainConstants.defaultWindowSize);
    await WindowManager.focus();
  }

  Future<void> openPasswordGenerator() async {
    await MultiWindowService.instance.openWindow(
      type: SubWindowType.passwordGenerator,
    );
  }

  Future<void> openAppDirectory() async {
    final openDirPlugin = OpenDir();
    final appDir = await AppPaths.appPath;
    await openDirPlugin.openNativeDir(path: appDir.path);
  }

  Future<void> exitApp() async {
    ref.read(appActivityModeProvider.notifier).setExiting();
    trayManager.removeListener(this);
    await trayManager.destroy();
    await WindowManager.close();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(showFromTray());
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key == null) {
      logWarning('Tray menu item clicked with null key', tag: _logTag);
      return;
    }

    final menuItemKey = AppTrayMenuItemKeyExtension.fromKey(key);
    if (menuItemKey == null) {
      logWarning('Unknown tray menu item key: $key', tag: _logTag);
      return;
    }

    switch (menuItemKey) {
      case AppTrayMenuItemKey.showWindow:
        unawaited(showFromTray());
      case AppTrayMenuItemKey.hideToTray:
        unawaited(hideToTray());
      case AppTrayMenuItemKey.passwordGenerator:
        unawaited(openPasswordGenerator());
      case AppTrayMenuItemKey.exitApp:
        unawaited(exitApp());
      case AppTrayMenuItemKey.pathLauncher:
        unawaited(openAppDirectory());
    }
  }

  void dispose() {
    if (!_initialized) {
      return;
    }

    trayManager.removeListener(this);
    _initialized = false;
  }
}
