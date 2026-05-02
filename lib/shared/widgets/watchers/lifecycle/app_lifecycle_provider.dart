import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/setup/setup_tray.dart';

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

final isAppActiveProvider = Provider<bool>((ref) {
  return ref.watch(appLifecycleProvider) == AppLifecycleState.resumed;
});

final appVisibleProvider = Provider<bool>((ref) {
  final isWindowLifecycleVisible = switch (ref.watch(appLifecycleProvider)) {
    AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    AppLifecycleState.hidden ||
    AppLifecycleState.paused ||
    AppLifecycleState.detached => false,
  };

  return isWindowLifecycleVisible && !ref.watch(appInTrayProvider);
});

class AppActivityScope extends ConsumerWidget {
  const AppActivityScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAppVisible = ref.watch(appVisibleProvider);

    return Offstage(
      offstage: !isAppVisible,
      child: TickerMode(enabled: isAppVisible, child: child),
    );
  }
}
