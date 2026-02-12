import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/watchers/lifecycle/app_lifecycle_provider.dart';

class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(appLifecycleProvider.notifier);
    _listener = AppLifecycleListener(
      onDetach: notifier.onDetach,
      onHide: notifier.onHide,
      onInactive: notifier.onInactive,
      onPause: notifier.onPause,
      onRestart: notifier.onRestart,
      onResume: notifier.onResume,
      onShow: notifier.onShow,
      onExitRequested: notifier.onExitRequested,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
