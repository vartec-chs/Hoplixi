import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

/// Темы кнопок приложения
abstract final class ButtonThemes {
  /// Адаптивные отступы для кнопок в зависимости от платформы
  static EdgeInsets _adaptivePadding(BuildContext context) {
    if (UniversalPlatform.isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    } else if (UniversalPlatform.isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 28.0, vertical: 18.0);
    } else if (UniversalPlatform.isWeb) {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
    }
    final size = MediaQuery.of(context).size;
    return EdgeInsets.symmetric(
      horizontal: size.width * 0.05,
      vertical: size.height * 0.015,
    );
  }

  /// Адаптивная тема для ElevatedButton
  static ElevatedButtonThemeData adaptiveElevatedButtonTheme(
    BuildContext context,
    ThemeData baseTheme,
  ) {
    return ElevatedButtonThemeData(
      style: baseTheme.elevatedButtonTheme.style?.copyWith(
        padding: WidgetStateProperty.all(_adaptivePadding(context)),
      ),
    );
  }

  /// Адаптивная тема для FilledButton
  static FilledButtonThemeData adaptiveFilledButtonTheme(
    BuildContext context,
    ThemeData baseTheme,
  ) {
    return FilledButtonThemeData(
      style: baseTheme.filledButtonTheme.style?.copyWith(
        padding: WidgetStateProperty.all(_adaptivePadding(context)),
      ),
    );
  }

  /// Адаптивная тема для OutlinedButton
  static OutlinedButtonThemeData adaptiveOutlinedButtonTheme(
    BuildContext context,
    ThemeData baseTheme,
  ) {
    return OutlinedButtonThemeData(
      style: baseTheme.outlinedButtonTheme.style?.copyWith(
        padding: WidgetStateProperty.all(_adaptivePadding(context)),
      ),
    );
  }

  /// Адаптивная тема для TextButton
  static TextButtonThemeData adaptiveTextButtonTheme(
    BuildContext context,
    ThemeData baseTheme,
  ) {
    return TextButtonThemeData(
      style: baseTheme.textButtonTheme.style?.copyWith(
        padding: WidgetStateProperty.all(_adaptivePadding(context)),
      ),
    );
  }
}
