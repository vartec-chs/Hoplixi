import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/theme_provider.dart';
import 'package:universal_platform/universal_platform.dart';

class ThemeWindowSyncService {
  ThemeWindowSyncService._();

  static final ThemeWindowSyncService instance = ThemeWindowSyncService._();

  static const String _methodSetTheme = 'theme_sync_set';
  static const String _methodGetTheme = 'theme_sync_get';

  ThemeProvider? _mainNotifier;
  ThemeProvider? _subNotifier;
  ThemeMode? _pendingSubTheme;
  ThemeMode? _suppressedOutboundMode;

  bool _mainHandlerInitialized = false;

  Future<void> bindMainNotifier(ThemeProvider notifier) async {
    _mainNotifier = notifier;

    if (!UniversalPlatform.isDesktop) return;
    if (_mainHandlerInitialized) return;

    final controller = await WindowController.fromCurrentEngine();
    await controller.setWindowMethodHandler((call) async {
      if (call.method == _methodGetTheme) {
        return _mainNotifier?.state.value?.name;
      }
      if (call.method != _methodSetTheme) return null;

      final mode = _parseThemeMode(call.arguments);
      if (mode == null || _mainNotifier == null) return null;

      await _applyIncomingTheme(
        notifier: _mainNotifier!,
        mode: mode,
        persist: true,
      );
      return 'ok';
    });

    _mainHandlerInitialized = true;
  }

  Future<void> bindSubNotifier(ThemeProvider notifier) async {
    _subNotifier = notifier;

    final pending = _pendingSubTheme;
    if (pending != null) {
      _pendingSubTheme = null;
      await _applyIncomingTheme(
        notifier: notifier,
        mode: pending,
        persist: false,
      );
      return;
    }

    final initial = await _requestMainTheme();
    if (initial == null) return;

    await _applyIncomingTheme(
      notifier: notifier,
      mode: initial,
      persist: false,
    );
  }

  Future<void> handleIncomingForSub(dynamic rawMode) async {
    final mode = _parseThemeMode(rawMode);
    if (mode == null) return;

    final notifier = _subNotifier;
    if (notifier == null) {
      _pendingSubTheme = mode;
      return;
    }

    await _applyIncomingTheme(notifier: notifier, mode: mode, persist: false);
  }

  bool consumeSuppressedOutboundFlag(ThemeMode mode) {
    if (_suppressedOutboundMode != mode) return false;
    _suppressedOutboundMode = null;
    return true;
  }

  Future<void> broadcastFromMain(ThemeMode mode) async {
    if (!UniversalPlatform.isDesktop) return;
    final controllers = await WindowController.getAll();

    for (final controller in controllers) {
      if (controller.windowId == '0') continue;

      try {
        await controller.invokeMethod(_methodSetTheme, mode.name);
      } catch (_) {
        // Ignore: окно могло закрыться между getAll и invokeMethod
      }
    }
  }

  Future<void> broadcastFromSub(ThemeMode mode) async {
    if (!UniversalPlatform.isDesktop) return;
    try {
      final mainController = WindowController.fromWindowId('0');
      await mainController.invokeMethod(_methodSetTheme, mode.name);
    } catch (_) {
      // Ignore: главное окно может быть уже закрыто
    }
  }

  Future<void> _applyIncomingTheme({
    required ThemeProvider notifier,
    required ThemeMode mode,
    required bool persist,
  }) async {
    _suppressedOutboundMode = mode;
    await notifier.setThemeMode(mode, persist: persist);
  }

  Future<ThemeMode?> _requestMainTheme() async {
    if (!UniversalPlatform.isDesktop) return null;
    try {
      final mainController = WindowController.fromWindowId('0');
      final raw = await mainController.invokeMethod<String>(_methodGetTheme);
      return _parseThemeMode(raw);
    } catch (_) {
      return null;
    }
  }

  ThemeMode? _parseThemeMode(dynamic raw) {
    if (raw is! String) return null;

    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
