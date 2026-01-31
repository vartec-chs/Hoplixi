import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

class AppLifecycleNotifier extends Notifier<AppLifecycleState> {
  static const String _logTag = 'AppLifecycle';
  @override
  AppLifecycleState build() {
    return AppLifecycleState.resumed;
  }

  void onDetach() {
    logInfo('App lifecycle: detached', tag: _logTag);
    state = AppLifecycleState.detached;
  }

  void onHide() {
    logInfo('App lifecycle: hidden', tag: _logTag);
    state = AppLifecycleState.hidden;
  }

  void onInactive() {
    logInfo('App lifecycle: inactive', tag: _logTag);
    state = AppLifecycleState.inactive;
  }

  void onPause() {
    logInfo('App lifecycle: paused', tag: _logTag);
    state = AppLifecycleState.paused;
  }

  void onRestart() {
    logInfo('App lifecycle: restarted', tag: _logTag);
  }

  void onResume() {
    logInfo('App lifecycle: resumed', tag: _logTag);
    state = AppLifecycleState.resumed;
  }

  void onShow() {
    logInfo('App lifecycle: shown', tag: _logTag);
  }

  Future<AppExitResponse> onExitRequested() async {
    logInfo('App lifecycle: exit requested', tag: _logTag);
    // Закрываем базу данных, если она открыта
    final dbState = await ref.read(mainStoreProvider.future);
    if (dbState.isOpen) {
      logInfo('Closing database before app exit', tag: _logTag);
      await ref.read(mainStoreProvider.notifier).closeStore();
    }

    return AppExitResponse.exit;
  }
}

final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
      AppLifecycleNotifier.new,
    );
