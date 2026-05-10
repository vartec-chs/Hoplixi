import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';

Color? getScreenBackgroundColor(BuildContext context, WidgetRef ref) {
  final isAnimatedEnabled =
      ref.watch(animatedBackgroundEnabledProvider).value ?? true;
  final isSmallScreen =
      MediaQuery.sizeOf(context).width < MainConstants.kMobileBreakpoint;

  if (isAnimatedEnabled && !isSmallScreen) {
    return Colors.transparent;
  }
  return null;
}
