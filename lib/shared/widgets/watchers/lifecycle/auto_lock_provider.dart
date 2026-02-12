import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/settings/providers/settings_provider.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

/// Состояние автоблокировки
/// Хранит оставшееся время в секундах или null, если таймер не активен
class AutoLockState {
  final int? remainingSeconds;
  final int totalDuration;

  const AutoLockState({
    this.remainingSeconds,
    this.totalDuration = 30, // 5 минут по умолчанию
  });

  bool get isWarning => remainingSeconds != null && remainingSeconds! <= 30;

  AutoLockState copyWith({
    int? remainingSeconds,
    int? totalDuration,
    bool forceNullRemaining = false,
  }) {
    return AutoLockState(
      remainingSeconds: forceNullRemaining
          ? null
          : (remainingSeconds ?? this.remainingSeconds),
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

class AutoLockNotifier extends Notifier<AutoLockState> {
  Timer? _timer;
  static const String _tag = 'AutoLock';

  @override
  AutoLockState build() {
    // Загружаем таймаут из настроек
    final settings = ref.watch(settingsProvider);
    final timeout = settings[AppKeys.autoLockTimeout.key] as int? ?? 300;

    // Слушаем изменения настроек таймаута
    ref.listen(settingsProvider, (previous, next) {
      final newTimeout = next[AppKeys.autoLockTimeout.key] as int? ?? 300;
      final oldTimeout = previous?[AppKeys.autoLockTimeout.key] as int? ?? 300;

      if (newTimeout != oldTimeout) {
        logInfo(
          'Auto-lock timeout changed: $oldTimeout -> $newTimeout',
          tag: _tag,
        );
        setDuration(newTimeout);

        // Если таймаут установлен в 0, останавливаем таймер
        if (newTimeout == 0) {
          stopTimer();
        }
      }
    });

    // Слушаем изменения жизненного цикла
    ref.listen(appLifecycleProvider, (previous, next) {
      _handleLifecycleChange(next);
    });

    // Слушаем изменения состояния БД
    ref.listen(mainStoreProvider, (previous, next) {
      next.whenData((dbState) {
        // Если БД закрылась или заблокировалась, останавливаем таймер
        if (!dbState.isOpen) {
          stopTimer();
        }
      });
    });

    return AutoLockState(totalDuration: timeout);
  }

  void setDuration(int seconds) {
    state = state.copyWith(totalDuration: seconds);
    logInfo('Auto-lock duration set to $seconds seconds', tag: _tag);
  }

  void _handleLifecycleChange(AppLifecycleState lifecycleState) {
    final dbState = ref.read(mainStoreProvider).value;
    final isDbOpen = dbState?.isOpen ?? false;

    // Проверяем, что таймаут не равен 0 (отключено)
    if (state.totalDuration == 0) {
      logInfo('Auto-lock is disabled (timeout = 0)', tag: _tag);
      return;
    }

    if (lifecycleState != AppLifecycleState.resumed && isDbOpen) {
      startTimer();
    } else {
      stopTimer();
    }
  }

  void startTimer() {
    // Не запускаем таймер, если автоблокировка отключена
    if (state.totalDuration == 0) {
      logInfo('Auto-lock timer not started (disabled)', tag: _tag);
      return;
    }

    stopTimer();
    logInfo('Starting auto-lock timer (${state.totalDuration}s)', tag: _tag);

    state = state.copyWith(remainingSeconds: state.totalDuration);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentRemaining = state.remainingSeconds;

      if (currentRemaining == null || currentRemaining <= 0) {
        _triggerLock();
        stopTimer();
        return;
      }

      state = state.copyWith(remainingSeconds: currentRemaining - 1);
    });
  }

  void stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      if (state.remainingSeconds != null) {
        logInfo('Auto-lock timer stopped', tag: _tag);
        state = state.copyWith(forceNullRemaining: true);
      }
    }
  }

  Future<void> _triggerLock() async {
    logInfo('Auto-lock triggered', tag: _tag);
    await ref.read(mainStoreProvider.notifier).lockStore();
  }
}

final autoLockProvider = NotifierProvider<AutoLockNotifier, AutoLockState>(
  AutoLockNotifier.new,
);
