import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:universal_platform/universal_platform.dart';

enum AppTrayMenuItemKey {
  showWindow('show_window'),
  passwordGenerator('password_generator'),
  exitApp('exit_app'),
  pathLauncher('path_launcher');

  final String key;
  const AppTrayMenuItemKey(this.key);
}

extension AppTrayMenuItemKeyExtension on AppTrayMenuItemKey {
  static AppTrayMenuItemKey? fromKey(String key) {
    for (var item in AppTrayMenuItemKey.values) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }
}

Future<void> setupTray() async {
  if (!UniversalPlatform.isDesktop) return;

  await trayManager.setIcon(
    Platform.isWindows ? 'assets/logo/logo.ico' : 'assets/logo/logo.png',
  );
  Menu menu = Menu(
    items: [
      MenuItem(key: AppTrayMenuItemKey.showWindow.key, label: 'Показать окно'),
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
  await trayManager.setToolTip('Hoplixi');
}
