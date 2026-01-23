import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets the system UI overlay style based on the provided theme and color scheme.
/// This function configures the status bar and navigation bar colors and icon brightness
/// to match the app's theme.
void setSystemUiOverlayStyle(ThemeData theme) {
  final mySystemTheme = SystemUiOverlayStyle(
    statusBarColor: theme.colorScheme.surface,
    statusBarIconBrightness: theme.colorScheme.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarColor: theme.colorScheme.surface,
    systemNavigationBarIconBrightness:
        theme.colorScheme.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
  );

  SystemChrome.setSystemUIOverlayStyle(mySystemTheme);
}
