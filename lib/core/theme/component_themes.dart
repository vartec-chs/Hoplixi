import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

/// Темы компонентов приложения
abstract final class ComponentThemes {
  /// Адаптивная тема для ListTile
  static ListTileThemeData adaptiveListTileTheme() {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
    );
  }

  /// Базовые подтемы для светлой темы
  static const FlexSubThemesData lightSubThemes = FlexSubThemesData(
    useM2StyleDividerInM3: true,
    interactionEffects: false,
    splashType: FlexSplashType.defaultSplash,
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    defaultRadius: 16.0,
    outlinedButtonOutlineSchemeColor: SchemeColor.secondary,
    toggleButtonsBorderSchemeColor: SchemeColor.secondary,
    segmentedButtonSchemeColor: SchemeColor.secondary,
    segmentedButtonBorderSchemeColor: SchemeColor.secondary,
    switchThumbSchemeColor: SchemeColor.onPrimary,
    sliderBaseSchemeColor: SchemeColor.primary,
    sliderThumbSchemeColor: SchemeColor.primary,
    sliderIndicatorSchemeColor: SchemeColor.primary,
    inputDecoratorSchemeColor: SchemeColor.primary,
    inputDecoratorIsFilled: true,
    inputDecoratorContentPadding: EdgeInsetsDirectional.fromSTEB(
      12,
      16,
      12,
      12,
    ),
    inputDecoratorBackgroundAlpha: 7,
    inputDecoratorBorderSchemeColor: SchemeColor.primary,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 2.0,
    inputDecoratorPrefixIconSchemeColor: SchemeColor.onPrimaryFixedVariant,
    inputDecoratorSuffixIconSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabSchemeColor: SchemeColor.primary,
    tooltipRadius: 13,
    tooltipWaitDuration: Duration(milliseconds: 100),
    tooltipShowDuration: Duration(milliseconds: 200),
    tooltipSchemeColor: SchemeColor.tertiary,
    tooltipOpacity: null,
    useInputDecoratorThemeInDialogs: true,
    timePickerElementRadius: 16.0,
    snackBarRadius: 16,
    snackBarBackgroundSchemeColor: SchemeColor.surfaceContainerHigh,
    snackBarActionSchemeColor: SchemeColor.primary,
    tabBarTabAlignment: TabAlignment.start,
    tabBarIndicatorAnimation: TabIndicatorAnimation.elastic,
    bottomNavigationBarShowUnselectedLabels: false,
    menuRadius: 16.0,
    menuBarRadius: 16.0,
    searchBarRadius: 16.0,
    searchViewRadius: 16.0,
    navigationBarLabelBehavior:
        NavigationDestinationLabelBehavior.onlyShowSelected,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailUnselectedLabelSchemeColor: SchemeColor.onPrimary,
    navigationRailMutedUnselectedLabel: true,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUnselectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailMutedUnselectedIcon: true,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailLabelType: NavigationRailLabelType.selected,
  );

  /// Базовые подтемы для тёмной темы
  static const FlexSubThemesData darkSubThemes = FlexSubThemesData(
    interactionEffects: false,
    useM2StyleDividerInM3: true,
    splashType: FlexSplashType.defaultSplash,
    defaultRadius: 16.0,
    outlinedButtonOutlineSchemeColor: SchemeColor.secondary,
    toggleButtonsBorderSchemeColor: SchemeColor.secondary,
    segmentedButtonSchemeColor: SchemeColor.secondary,
    segmentedButtonBorderSchemeColor: SchemeColor.secondary,
    switchThumbSchemeColor: SchemeColor.onPrimary,
    sliderBaseSchemeColor: SchemeColor.primary,
    sliderThumbSchemeColor: SchemeColor.primary,
    sliderIndicatorSchemeColor: SchemeColor.primary,
    inputDecoratorSchemeColor: SchemeColor.tertiary,
    inputDecoratorIsFilled: true,
    inputDecoratorContentPadding: EdgeInsetsDirectional.fromSTEB(
      12,
      16,
      12,
      12,
    ),
    inputDecoratorBackgroundAlpha: 70,
    inputDecoratorBorderSchemeColor: SchemeColor.primary,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: false,
    inputDecoratorFocusedBorderWidth: 2.0,
    inputDecoratorSuffixIconSchemeColor: SchemeColor.primary,
    inputCursorSchemeColor: SchemeColor.primary,
    fabUseShape: true,
    fabSchemeColor: SchemeColor.primary,
    tooltipRadius: 13,
    tooltipWaitDuration: Duration(milliseconds: 100),
    tooltipShowDuration: Duration(milliseconds: 200),
    tooltipSchemeColor: SchemeColor.tertiary,
    tooltipOpacity: null,
    useInputDecoratorThemeInDialogs: true,
    timePickerElementRadius: 16.0,
    snackBarRadius: 16,
    snackBarBackgroundSchemeColor: SchemeColor.surfaceContainerHigh,
    snackBarActionSchemeColor: SchemeColor.primary,
    tabBarItemSchemeColor: SchemeColor.primary,
    tabBarTabAlignment: TabAlignment.start,
    tabBarIndicatorAnimation: TabIndicatorAnimation.elastic,
    bottomNavigationBarShowUnselectedLabels: false,
    menuRadius: 16.0,
    menuBarRadius: 16.0,
    searchBarRadius: 16.0,
    searchViewRadius: 16.0,
    navigationBarLabelBehavior:
        NavigationDestinationLabelBehavior.onlyShowSelected,
    navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
    navigationRailUnselectedLabelSchemeColor: SchemeColor.onPrimary,
    navigationRailMutedUnselectedLabel: true,
    navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailUnselectedIconSchemeColor: SchemeColor.onPrimary,
    navigationRailMutedUnselectedIcon: true,
    navigationRailUseIndicator: true,
    navigationRailIndicatorSchemeColor: SchemeColor.primary,
    navigationRailLabelType: NavigationRailLabelType.selected,
  );
}

enum ButtonSize { small, medium, large }

enum ButtonType { elevated, filled, text, outlined }

ButtonStyle buttonStyle(
  BuildContext context, {
  required ButtonType type,
  required ButtonSize size,
}) {
  // Берём базовый стиль из темы в зависимости от типа кнопки
  final baseStyle =
      switch (type) {
        ButtonType.elevated => ElevatedButtonTheme.of(context).style,
        ButtonType.filled => FilledButtonTheme.of(context).style,
        ButtonType.text => TextButtonTheme.of(context).style,
        ButtonType.outlined => OutlinedButtonTheme.of(context).style,
      } ??
      const ButtonStyle();

  // Размеры
  final (padding, fontSize, minSize) = switch (size) {
    ButtonSize.small => (
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      12.0,
      const Size(64, 32),
    ),
    ButtonSize.medium => (
      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      14.0,
      const Size(88, 40),
    ),
    ButtonSize.large => (
      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      16.0,
      const Size(120, 48),
    ),
  };

  return baseStyle.copyWith(
    padding: WidgetStateProperty.all(padding),
    textStyle: WidgetStateProperty.all(
      Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: fontSize),
    ),
    minimumSize: WidgetStateProperty.all(minSize),
  );
}
