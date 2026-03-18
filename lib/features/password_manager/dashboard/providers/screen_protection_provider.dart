import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';
import 'package:no_screenshot/no_screenshot.dart';

final dashboardScreenProtectionProvider =
    NotifierProvider<DashboardScreenProtectionNotifier, bool>(
      DashboardScreenProtectionNotifier.new,
    );

final class DashboardScreenProtectionNotifier extends Notifier<bool> {
  static const String _logTag = 'DashboardScreenProtection';

  bool _isProtectionActive = false;
  bool? _lastAppliedValue;

  @override
  bool build() {
    final enabled =
        ref.watch(preventScreenCaptureOnDashboardProvider).value ?? true;

    ref.listen(preventScreenCaptureOnDashboardProvider, (previous, next) {
      final previousValue = previous?.value ?? true;
      final nextValue = next.value ?? true;

      if (previousValue != nextValue) {
        unawaited(_applyProtection(nextValue));
      }
    });

    ref.onDispose(() {
      unawaited(_deactivateProtection());
    });

    unawaited(_applyProtection(enabled));
    return enabled;
  }

  Future<void> _applyProtection(bool enabled) async {
    if (_lastAppliedValue == enabled) {
      state = enabled;
      return;
    }

    try {
      if (enabled) {
        if (!_isProtectionActive) {
          await _activateProtection();
          _isProtectionActive = true;
          logInfo('Dashboard screen protection enabled', tag: _logTag);
        }
      } else if (_isProtectionActive) {
        await _deactivateProtection();
        _isProtectionActive = false;
        logInfo('Dashboard screen protection disabled', tag: _logTag);
      }

      _lastAppliedValue = enabled;
      state = enabled;
    } catch (error, stackTrace) {
      logError(
        'Failed to update dashboard screen protection: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  Future<void> _activateProtection() async {
    await NoScreenshot.instance.screenshotOff();
  }

  Future<void> _deactivateProtection() async {
    if (!_isProtectionActive) {
      return;
    }

    await NoScreenshot.instance.screenshotOn();
    _isProtectionActive = false;
  }
}
