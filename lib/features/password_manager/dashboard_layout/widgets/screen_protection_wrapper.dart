import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Обёртка для максимальной защиты экрана.
///
/// Активирует защиту через `no_screenshot` на всех поддерживаемых платформах.
///
/// Поддержка зависит от платформы:
/// - **Android / iOS / macOS / Windows**: нативная защита через API пакета.
/// - **Linux**: best-effort, состояние отслеживается, но compositor может
///   не позволить реально скрыть содержимое.
/// - **Web**: best-effort, пакет включает лишь браузерные deterrents.
///
/// Виджет по-прежнему просто отображает [child], но состояние защиты
/// применяется через пакет для любой поддерживаемой платформы.
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
    try {
      await NoScreenshot.instance.screenshotOff();

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
      await NoScreenshot.instance.screenshotOn();

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
  @override
  Widget build(BuildContext context) => widget.child;
}
