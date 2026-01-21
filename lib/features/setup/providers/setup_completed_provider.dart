import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/di_init.dart';

/// Провайдер для проверки, завершена ли первоначальная настройка
///
/// Возвращает `true` если настройка завершена, `false` если нужно показать
/// экран Setup
final setupCompletedProvider = FutureProvider<bool>((ref) async {
  final storage = getIt<AppStorageService>();
  final completed = await storage.get(AppKeys.setupCompleted);
  return completed ?? false;
});

/// Провайдер для принудительного обновления состояния setupCompleted
class SetupCompletedNotifier extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() async {
    final storage = getIt<AppStorageService>();
    final completed = await storage.get(AppKeys.setupCompleted);
    return completed ?? false;
  }

  /// Пометить настройку как завершённую
  Future<void> markAsCompleted() async {
    final storage = getIt<AppStorageService>();
    await storage.set(AppKeys.setupCompleted, true);
    state = const AsyncData(true);
  }

  /// Сбросить статус настройки (для тестирования)
  Future<void> reset() async {
    final storage = getIt<AppStorageService>();
    await storage.set(AppKeys.setupCompleted, false);
    state = const AsyncData(false);
  }
}

/// Провайдер с возможностью обновления состояния
final setupCompletedNotifierProvider =
    AsyncNotifierProvider<SetupCompletedNotifier, bool>(
      SetupCompletedNotifier.new,
    );
