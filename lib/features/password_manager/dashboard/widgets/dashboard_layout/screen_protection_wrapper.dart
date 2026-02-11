import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:universal_platform/universal_platform.dart';

/// Обёртка для максимальной защиты экрана.
///
/// Активирует защиту только на Android и iOS:
/// - **Android**: `protectDataLeakageOn` — включает FLAG_SECURE,
///   что предотвращает скриншоты, запись экрана и скрывает
///   содержимое в app switcher.
/// - **iOS**: `preventScreenshotOn` — предотвращает скриншоты
///   и запись экрана; `protectDataLeakageWithBlur` — размывает
///   содержимое при переходе в фон (app switcher).
///
/// На других платформах (desktop, web) виджет просто
/// отображает [child] без каких-либо действий.
class ScreenProtectionWrapper extends StatefulWidget {
  /// Дочерний виджет, оборачиваемый защитой.
  final Widget child;

  const ScreenProtectionWrapper({required this.child, super.key});

  @override
  State<ScreenProtectionWrapper> createState() =>
      _ScreenProtectionWrapperState();
}

class _ScreenProtectionWrapperState extends State<ScreenProtectionWrapper> {
  /// Флаг, указывающий, что защита активирована
  /// и её нужно отключить при dispose.
  bool _isProtectionActive = false;

  @override
  void initState() {
    super.initState();
    _activateProtection();
  }

  @override
  void dispose() {
    _deactivateProtection();
    super.dispose();
  }

  Future<void> _activateProtection() async {
    if (!_isMobilePlatform) return;

    try {
      if (UniversalPlatform.isAndroid) {
        await _activateAndroidProtection();
      } else if (UniversalPlatform.isIOS) {
        await _activateIOSProtection();
      }

      _isProtectionActive = true;
      developer.log(
        'Screen protection activated',
        name: 'ScreenProtectionWrapper',
      );
    } catch (e, s) {
      developer.log(
        'Failed to activate screen protection',
        name: 'ScreenProtectionWrapper',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _deactivateProtection() async {
    if (!_isProtectionActive) return;

    try {
      if (UniversalPlatform.isAndroid) {
        await _deactivateAndroidProtection();
      } else if (UniversalPlatform.isIOS) {
        await _deactivateIOSProtection();
      }

      _isProtectionActive = false;
      developer.log(
        'Screen protection deactivated',
        name: 'ScreenProtectionWrapper',
      );
    } catch (e, s) {
      developer.log(
        'Failed to deactivate screen protection',
        name: 'ScreenProtectionWrapper',
        error: e,
        stackTrace: s,
      );
    }
  }

  // ===========================================================================
  // Android Protection
  // ===========================================================================

  /// На Android `protectDataLeakageOn()` устанавливает
  /// FLAG_SECURE на окно активности, что одновременно:
  /// - Предотвращает скриншоты
  /// - Предотвращает запись экрана
  /// - Скрывает содержимое в app switcher
  Future<void> _activateAndroidProtection() async {
    await ScreenProtector.protectDataLeakageOn();
  }

  Future<void> _deactivateAndroidProtection() async {
    await ScreenProtector.protectDataLeakageOff();
  }

  // ===========================================================================
  // iOS Protection
  // ===========================================================================

  /// На iOS используем комбинацию методов:
  /// - `preventScreenshotOn` — предотвращает скриншоты
  ///   и запись экрана
  /// - `protectDataLeakageWithBlur` — размывает содержимое
  ///   при переходе в фон (app switcher)
  Future<void> _activateIOSProtection() async {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  Future<void> _deactivateIOSProtection() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageWithBlurOff();
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  bool get _isMobilePlatform =>
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  @override
  Widget build(BuildContext context) => widget.child;
}
