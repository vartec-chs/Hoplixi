import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/di_init.dart';

final themeProvider = AsyncNotifierProvider<ThemeProvider, ThemeMode>(
  ThemeProvider.new,
);

class ThemeProvider extends AsyncNotifier<ThemeMode> {
  @override
  FutureOr<ThemeMode> build() async {
    state = const AsyncValue.loading();
    try {
      final storage = getIt.get<AppStorageService>();
      String? themeMode = await storage.get(AppKeys.themeMode);
      if (themeMode == 'light') {
        state = const AsyncData(ThemeMode.light);
        return ThemeMode.light;
      } else if (themeMode == 'dark') {
        state = const AsyncData(ThemeMode.dark);
        return ThemeMode.dark;
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
      final storage = getIt.get<AppStorageService>();
      if (themeMode == ThemeMode.light) {
        await storage.set(AppKeys.themeMode, 'light');
      } else if (themeMode == ThemeMode.dark) {
        await storage.set(AppKeys.themeMode, 'dark');
      } else {
        await storage.set(AppKeys.themeMode, 'system');
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
