import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logger/index.dart';

class LaunchAtStartupService {
  final _log = loggerWithTag('LaunchAtStartupService');
  static const String startInTrayArg = '--start-in-tray';

  bool _isConfigured = false;

  bool get _isDesktopPlatform {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  Future<void> setup() async {
    if (!_isDesktopPlatform || _isConfigured) {
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        packageName: packageInfo.packageName,
        args: const [startInTrayArg],
      );

      _isConfigured = true;
    } catch (error, stackTrace) {
      _log.error(
        'Не удалось инициализировать launch_at_startup',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> isEnabled() async {
    if (!_isDesktopPlatform) {
      return false;
    }

    await setup();

    try {
      return await launchAtStartup.isEnabled();
    } catch (error, stackTrace) {
      _log.error(
        'Не удалось получить состояние автозапуска',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!_isDesktopPlatform) {
      return false;
    }

    await setup();

    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }

      return await launchAtStartup.isEnabled();
    } catch (error, stackTrace) {
      _log.error(
        'Не удалось изменить состояние автозапуска',
        error: error,
        stackTrace: stackTrace,
        data: {'enabled': enabled},
      );
      return false;
    }
  }
}
