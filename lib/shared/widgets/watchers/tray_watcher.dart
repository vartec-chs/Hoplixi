import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/setup/setup_tray.dart';
import 'package:universal_platform/universal_platform.dart';

/// Виджет-обёртка, инициализирующая сервис tray через Riverpod.
class TrayWatcher extends ConsumerStatefulWidget {
  const TrayWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TrayWatcher> createState() => _TrayWatcherState();
}

class _TrayWatcherState extends ConsumerState<TrayWatcher> {
  static const String _logTag = 'TrayWatcher';

  @override
  void initState() {
    super.initState();

    if (!UniversalPlatform.isDesktop) {
      return;
    }

    unawaited(_initTrayService());
  }

  Future<void> _initTrayService() async {
    try {
      await ref.read(trayServiceProvider).init();
    } catch (error, stackTrace) {
      logError(
        'Failed to initialize tray service',
        tag: _logTag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
