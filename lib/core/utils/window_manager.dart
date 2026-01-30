import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

class WindowManager {
  static Future<void> initialize() async {
    if (UniversalPlatform.isWindows) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        title: MainConstants.appName,
        minimumSize: MainConstants.minWindowSize, // Минимальный размер окна
        maximumSize: MainConstants.maxWindowSize, // Максимальный размер окна
        size: MainConstants.defaultWindowSize, // Начальный размер окна
        center: MainConstants.isCenter, // Центрировать окно при
        titleBarStyle:
            TitleBarStyle.hidden, // Скрыть стандартную панель заголовка
        skipTaskbar: false,
      );

      await windowManager.waitUntilReadyToShow(windowOptions).then((_) async {
        await windowManager.show();
        await windowManager.focus();
      });

      windowManager.addListener(_AppWindowListener());
    }
  }

  static Future<void> show() async {
    if (UniversalPlatform.isWindows) {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  static Future<void> hide() async {
    if (UniversalPlatform.isWindows) {
      await windowManager.hide();
    }
  }

  static Future<void> close() async {
    if (UniversalPlatform.isWindows) {
      await windowManager.close();
    }
  }

  static Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    if (UniversalPlatform.isWindows) {
      await windowManager.setAlwaysOnTop(isAlwaysOnTop);
    }
  }

  static Future<void> setFullScreen(bool isFullScreen) async {
    if (UniversalPlatform.isWindows) {
      await windowManager.setFullScreen(isFullScreen);
    }
  }

  // resize
  static Future<void> setSize(Size size) async {
    if (UniversalPlatform.isWindows) {
      await windowManager.setSize(size);
    }
  }

  // focus
  static Future<void> focus() async {
    if (UniversalPlatform.isWindows) {
      await windowManager.focus();
    }
  }

  //setTitle
  static Future<void> setTitle(String title) async {
    if (UniversalPlatform.isWindows) {
      await windowManager.setTitle(title);
    }
  }
}

class _AppWindowListener extends WindowListener {
  static const String _logTag = 'AppWindowListener';

  @override
  void onWindowClose() {
    logInfo('Window is closing', tag: _logTag);
    super.onWindowClose();
  }

  @override
  void onWindowFocus() {
    logInfo('Window is focused', tag: _logTag);
    super.onWindowFocus();
  }

  @override
  void onWindowBlur() {
    logInfo('Window lost focus', tag: _logTag);
    super.onWindowBlur();
  }

  @override
  void onWindowResize() {
    logInfo('Window resized', tag: _logTag);
    super.onWindowResize();
  }

  @override
  void onWindowMove() {
    // logInfo('Window moved', tag: _logTag);
    super.onWindowMove();
  }

  @override
  void onWindowDocked() {
    logInfo('Window docked', tag: _logTag);
    super.onWindowDocked();
  }

  @override
  void onWindowEnterFullScreen() {
    logInfo('Window entered full screen', tag: _logTag);
    super.onWindowEnterFullScreen();
  }

  @override
  void onWindowLeaveFullScreen() {
    logInfo('Window left full screen', tag: _logTag);
    super.onWindowLeaveFullScreen();
  }

  @override
  void onWindowMaximize() {
    logInfo('Window maximized', tag: _logTag);
    super.onWindowMaximize();
  }

  @override
  void onWindowMinimize() {
    logInfo('Window minimized', tag: _logTag);
    super.onWindowMinimize();
  }

  @override
  void onWindowMoved() {
    logInfo('Window moved', tag: _logTag);
    super.onWindowMoved();
  }

  @override
  void onWindowResized() {
    logInfo('Window resized', tag: _logTag);
    super.onWindowResized();
  }

  @override
  void onWindowRestore() {
    logInfo('Window restored', tag: _logTag);
    super.onWindowRestore();
  }

  @override
  void onWindowUndocked() {
    logInfo('Window undocked', tag: _logTag);
    super.onWindowUndocked();
  }

  @override
  void onWindowUnmaximize() {
    logInfo('Window unmaximized', tag: _logTag);
    super.onWindowUnmaximize();
  }
}
