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
  String? _lastAppliedSignature;

  @override
  bool build() {
    final enabled =
        ref.watch(preventScreenCaptureOnDashboardProvider).value ?? true;
    final blurEnabled =
        ref.watch(dashboardScreenBlurOverlayEnabledProvider).value ?? false;

    ref.listen(preventScreenCaptureOnDashboardProvider, (previous, next) {
      final previousValue = previous?.value ?? true;
      final nextValue = next.value ?? true;

      if (previousValue != nextValue) {
        final currentBlurEnabled =
            ref.read(dashboardScreenBlurOverlayEnabledProvider).value ?? false;
        unawaited(_applyProtection(nextValue, currentBlurEnabled));
      }
    });

    ref.listen(dashboardScreenBlurOverlayEnabledProvider, (previous, next) {
      final previousValue = previous?.value ?? false;
      final nextValue = next.value ?? false;

      if (previousValue != nextValue) {
        final currentEnabled =
            ref.read(preventScreenCaptureOnDashboardProvider).value ?? true;
        unawaited(_applyProtection(currentEnabled, nextValue));
      }
    });

    ref.onDispose(() {
      unawaited(_deactivateProtection());
    });

    unawaited(_applyProtection(enabled, blurEnabled));
    return enabled;
  }

  Future<void> _applyProtection(bool enabled, bool blurEnabled) async {
    final signature = '$enabled:$blurEnabled';
    if (_lastAppliedSignature == signature) {
      state = enabled;
      return;
    }

    try {
      if (enabled) {
        if (!_isProtectionActive) {
          await _activateProtection(blurEnabled);
          _isProtectionActive = true;
          logInfo('Dashboard screen protection enabled', tag: _logTag);
        } else {
          await _applyProtectionMode(blurEnabled);
        }
      } else if (_isProtectionActive) {
        await _deactivateProtection();
        _isProtectionActive = false;
        logInfo('Dashboard screen protection disabled', tag: _logTag);
      }

      _lastAppliedSignature = signature;
      state = enabled;
    } catch (error, stackTrace) {
      logError(
        'Failed to update dashboard screen protection: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  Future<void> _activateProtection(bool blurEnabled) async {
    await _applyProtectionMode(blurEnabled);
  }

  Future<void> _applyProtectionMode(bool blurEnabled) async {
    if (blurEnabled) {
      await NoScreenshot.instance.screenshotWithBlur(blurRadius: 30.0);
      return;
    }

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