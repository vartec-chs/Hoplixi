import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/system_prefs.dart';
import 'package:hoplixi/core/logger/logger.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';

/// Провайдер для проверки, завершена ли первоначальная настройка
///
/// Возвращает `true` если настройка завершена, `false` если нужно показать
/// экран Setup
final setupCompletedProvider = FutureProvider<bool>((ref) async {
  final storage = getIt<PreferencesService>();
  final completed = await storage.systemPrefs.getSetupCompleted();
  return completed ?? false;
});

/// Провайдер для принудительного обновления состояния setupCompleted
class SetupCompletedNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final storage = getIt<PreferencesService>();
    final completed = await storage.systemPrefs.getSetupCompleted();
    logInfo('Setup completed status: $completed');
    return completed ?? false;
  }

  /// Пометить настройку как завершённую
  Future<void> markAsCompleted() async {
    final storage = getIt<PreferencesService>();
    await storage.systemPrefs.setSetupCompleted(true);
    state = const AsyncData(true);
  }

  /// Сбросить статус настройки (для тестирования)
  Future<void> reset() async {
    final storage = getIt<PreferencesService>();
    await storage.systemPrefs.setSetupCompleted(false);
    state = const AsyncData(false);
  }
}

/// Провайдер с возможностью обновления состояния
final setupCompletedNotifierProvider =
    AsyncNotifierProvider<SetupCompletedNotifier, bool>(
      SetupCompletedNotifier.new,
    );
