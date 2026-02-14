import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/index.dart';

class LaunchDbPathNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setPath(String? path) {
    logTrace('Setting launch DB path: $path');
    state = path;
  }

  void clearPath() {
    state = null;
  }

  String? consumePath() {
    final path = state;
    state = null;
    return path;
  }
}

final launchDbPathProvider = NotifierProvider<LaunchDbPathNotifier, String?>(
  LaunchDbPathNotifier.new,
);
