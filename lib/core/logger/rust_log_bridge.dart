import 'dart:async';

import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/rust/api/logging.dart' as rust_api;

class RustLogBridge {
  RustLogBridge._();

  static final RustLogBridge instance = RustLogBridge._();

  static const String _tag = 'RustLogBridge';
  static const int _levelDebug = 10;
  static const int _levelInfo = 20;
  static const int _levelWarning = 30;
  static const int _levelError = 40;
  static const int _levelFatal = 50;

  StreamSubscription<rust_api.LogEntry>? _subscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _subscription = rust_api.createLogStream().listen(
        _onLogEntry,
        onError: (Object error, StackTrace stackTrace) {
          logError(
            'Rust log stream error',
            tag: _tag,
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      try {
        await rust_api.installRustLogBridge(level: _levelInfo);
      } catch (error, stackTrace) {
        logWarning(
          'Failed to install Rust log crate bridge: $error',
          tag: _tag,
          data: {'stackTrace': stackTrace.toString()},
        );
      }

      _initialized = true;
      logInfo('Rust log bridge initialized', tag: _tag);
    } catch (error, stackTrace) {
      logWarning(
        'Failed to initialize Rust log bridge: $error',
        tag: _tag,
        data: {'stackTrace': stackTrace.toString()},
      );
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void _onLogEntry(rust_api.LogEntry entry) {
    final tag = entry.tag.isEmpty ? 'Rust' : entry.tag;
    final data = <String, dynamic>{'rustTimeMillis': entry.timeMillis};

    if (entry.level >= _levelFatal) {
      logFatal(entry.msg, tag: tag, data: data);
      return;
    }

    if (entry.level >= _levelError) {
      logError(entry.msg, tag: tag, data: data);
      return;
    }

    if (entry.level >= _levelWarning) {
      logWarning(entry.msg, tag: tag, data: data);
      return;
    }

    if (entry.level >= _levelInfo) {
      logInfo(entry.msg, tag: tag, data: data);
      return;
    }

    if (entry.level >= _levelDebug) {
      logDebug(entry.msg, tag: tag, data: data);
      return;
    }

    logTrace(entry.msg, tag: tag, data: data);
  }
}
