import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/di_init.dart';

final localeProvider = AsyncNotifierProvider<LocaleProvider, Locale>(
  LocaleProvider.new,
);

class LocaleProvider extends AsyncNotifier<Locale> {
  static const Locale _fallbackLocale = Locale('en');
  static const Set<String> _supportedLanguageCodes = {'en', 'ru'};

  @override
  FutureOr<Locale> build() async {
    state = const AsyncValue.loading();

    try {
      final storage = getIt.get<AppStorageService>();
      final savedLanguageCode = await storage.get(AppKeys.language);

      final resolvedLocale = _resolveLocale(
        savedLanguageCode ??
            WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      );

      state = AsyncData(resolvedLocale);
      return resolvedLocale;
    } catch (_) {
      final resolvedLocale = _resolveLocale(
        WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      );

      state = AsyncData(resolvedLocale);
      return resolvedLocale;
    }
  }

  Locale _resolveLocale(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return _fallbackLocale;
    }

    final normalizedLanguageCode = languageCode.toLowerCase();
    if (_supportedLanguageCodes.contains(normalizedLanguageCode)) {
      return Locale(normalizedLanguageCode);
    }

    return _fallbackLocale;
  }

  Future<void> setLocale(Locale locale, {bool persist = true}) async {
    await setLocaleCode(locale.languageCode, persist: persist);
  }

  Future<void> setLocaleCode(String languageCode, {bool persist = true}) async {
    final resolvedLocale = _resolveLocale(languageCode);
    state = AsyncData(resolvedLocale);

    if (!persist) {
      return;
    }

    try {
      final storage = getIt.get<AppStorageService>();
      await storage.set(AppKeys.language, resolvedLocale.languageCode);
    } catch (_) {}
  }
}
