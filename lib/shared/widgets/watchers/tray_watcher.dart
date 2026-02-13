import 'package:flutter/widgets.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/core/multi_window/multi_window_service.dart';
import 'package:hoplixi/core/multi_window/sub_window_type.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:hoplixi/setup_tray.dart';
import 'package:open_dir/open_dir.dart';
import 'package:tray_manager/tray_manager.dart';

/// Виджет-обёртка, управляющая подпиской на события tray_manager.
class TrayWatcher extends StatefulWidget {
  const TrayWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<TrayWatcher> createState() => _TrayWatcherState();
}

class _TrayWatcherState extends State<TrayWatcher> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
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
      case AppTrayMenuItemKey.passwordGenerator:
        await MultiWindowService.instance.openWindow(
          type: SubWindowType.passwordGenerator,
        );
        break;
      case AppTrayMenuItemKey.exitApp:
        await WindowManager.close();
        break;
      case AppTrayMenuItemKey.pathLauncher:
        final openDirPlugin = OpenDir();
        final appDir = await AppPaths.appPath;
        await openDirPlugin.openNativeDir(path: appDir.path);
        break;
    }
    super.onTrayMenuItemClick(menuItem);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
