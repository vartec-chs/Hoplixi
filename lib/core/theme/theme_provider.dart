import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';

final themeProvider = AsyncNotifierProvider<ThemeProvider, ThemeMode>(
  ThemeProvider.new,
);

class ThemeProvider extends AsyncNotifier<ThemeMode> {
  @override
  FutureOr<ThemeMode> build() async {
    state = const AsyncValue.loading();
    try {
      final storage = getIt.get<PreferencesService>();
      final themeMode = await storage.settingsPrefs.themeMode.get();
      if (themeMode != null) {
        final mode = ThemeMode.values.firstWhere(
          (e) => e.name == themeMode,
          orElse: () => ThemeMode.system,
        );
        state = AsyncData(mode);
        return mode;
      } else {
        state = const AsyncData(ThemeMode.system);
        return ThemeMode.system;
      }
    } catch (e) {
      state = const AsyncData(ThemeMode.system);
      return ThemeMode.system;
    }
  }

  /// Сохраняет текущую тему в SharedPreferences
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final storage = getIt.get<PreferencesService>();
      if (themeMode == ThemeMode.light) {
        await storage.settingsPrefs.themeMode.set(ThemeMode.light);
      } else if (themeMode == ThemeMode.dark) {
        await storage.settingsPrefs.themeMode.set(ThemeMode.dark);
      } else {
        await storage.settingsPrefs.themeMode.set(ThemeMode.system);
      }
    } catch (e) {
      // logError(
      //   'Failed to save theme: $e',
      //   tag: 'Theme',
      //   stackTrace: stackTrace,
      // );
    }
  }

  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode themeMode, {bool persist = true}) async {
    state = AsyncData(themeMode);
    if (!persist) return;
    await _saveTheme(themeMode);
  }

  Future<void> toggleTheme() async {
    final currentTheme = state.value ?? ThemeMode.system;
    switch (currentTheme) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setLightTheme();
        break;
      case ThemeMode.system:
        // При системной теме переключаемся на противоположную
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.dark) {
          await setLightTheme();
        } else {
          await setDarkTheme();
        }
        break;
    }
  }
}
