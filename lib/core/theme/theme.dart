import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'button_themes.dart';
import 'colors.dart';
import 'component_themes.dart';

final visualDensity = VisualDensity.comfortable;
final desktopOnlyUseDialogBuilders = false;

WoltModalType buildModalType(BuildContext context) {
  if (UniversalPlatform.isDesktop && desktopOnlyUseDialogBuilders) {
    return WoltModalType.dialog();
  }
  final width = MediaQuery.sizeOf(context).width;
  if (width < 523) {
    return WoltModalType.bottomSheet();
  } else if (width < 800) {
    return WoltModalType.dialog();
  } else {
    return WoltModalType.dialog();
  }
}

abstract final class AppTheme {
  static const pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      // TargetPlatform.android: GoTransitions.material,
      TargetPlatform.iOS: GoTransitions.cupertino,
      // TargetPlatform.linux: GoTransitions.material,
      TargetPlatform.macOS: GoTransitions.cupertino,
      TargetPlatform.windows: GoTransitions.scale,
    },
  );

  // LIGHT THEME
  static ThemeData light(BuildContext context) {
    final bs = FlexThemeData.light(
      colors: AppColors.lightColors,
      useMaterial3ErrorColors: false,
      swapLegacyOnMaterial3: true,
      subThemesData: ComponentThemes.lightSubThemes,
      visualDensity: visualDensity,
      appBarStyle: FlexAppBarStyle.surface,
      transparentStatusBar: false,
      splashFactory: InkRipple.splashFactory,
      useMaterial3: true,
      error: AppColors.lightColors.error,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),

      errorContainer: AppColors.lightColors.errorContainer,
    );

    GoTransition.defaultCurve = Curves.easeInOut;
    GoTransition.defaultDuration = const Duration(milliseconds: 600);

    final base = bs.copyWith(
      dialogTheme: bs.dialogTheme.copyWith(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      cardTheme: bs.cardTheme.copyWith(margin: EdgeInsets.zero),
      elevatedButtonTheme: ButtonThemes.adaptiveElevatedButtonTheme(
        context,
        bs,
      ),
      filledButtonTheme: ButtonThemes.adaptiveFilledButtonTheme(context, bs),
      outlinedButtonTheme: ButtonThemes.adaptiveOutlinedButtonTheme(
        context,
        bs,
      ),
      textButtonTheme: ButtonThemes.adaptiveTextButtonTheme(context, bs),
      listTileTheme: ComponentThemes.adaptiveListTileTheme(),
      textTheme: GoogleFonts.nunitoTextTheme(bs.textTheme),
      dropdownMenuTheme: bs.dropdownMenuTheme.copyWith(
        menuStyle: bs.dropdownMenuTheme.menuStyle?.copyWith(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
      ),
      popupMenuTheme: bs.popupMenuTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // pageTransitionsTheme: pageTransitionsTheme,
      extensions: <ThemeExtension>[
        const WoltModalSheetThemeData(
          backgroundColor: Color(0xFFF5F5F5),
          surfaceTintColor: Colors.transparent,
          useSafeArea: true,
          enableDrag: true,
          modalTypeBuilder: buildModalType,
          mainContentScrollPhysics: ClampingScrollPhysics(),
        ),
      ],
    );

    return base;
  }

  // DARK THEME
  static ThemeData dark(BuildContext context) {
    final bs = FlexThemeData.dark(
      colors: AppColors.darkColors,
      useMaterial3ErrorColors: false,
      swapLegacyOnMaterial3: true,
      subThemesData: ComponentThemes.darkSubThemes,
      visualDensity: visualDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      surfaceTint: const Color(0xFF2E2E2E),
      appBarStyle: FlexAppBarStyle.scaffoldBackground,
      transparentStatusBar: false,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      error: AppColors.darkColors.error,
      errorContainer: AppColors.darkColors.errorContainer,
    );

    GoTransition.defaultCurve = Curves.easeInOut;
    GoTransition.defaultDuration = const Duration(milliseconds: 600);

    final base = bs.copyWith(
      dialogTheme: bs.dialogTheme.copyWith(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      cardTheme: bs.cardTheme.copyWith(margin: EdgeInsets.zero),
      elevatedButtonTheme: ButtonThemes.adaptiveElevatedButtonTheme(
        context,
        bs,
      ),
      filledButtonTheme: ButtonThemes.adaptiveFilledButtonTheme(context, bs),
      outlinedButtonTheme: ButtonThemes.adaptiveOutlinedButtonTheme(
        context,
        bs,
      ),
      textButtonTheme: ButtonThemes.adaptiveTextButtonTheme(context, bs),
      listTileTheme: ComponentThemes.adaptiveListTileTheme(),
      textTheme: GoogleFonts.nunitoTextTheme(bs.textTheme),
      dropdownMenuTheme: bs.dropdownMenuTheme.copyWith(
        menuStyle: bs.dropdownMenuTheme.menuStyle?.copyWith(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      popupMenuTheme: bs.popupMenuTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // pageTransitionsTheme: pageTransitionsTheme,
      extensions: <ThemeExtension>[
        const WoltModalSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          useSafeArea: true,
          enableDrag: true,
          modalTypeBuilder: buildModalType,
          mainContentScrollPhysics: ClampingScrollPhysics(),
          // dragHandleColor: Colors.white54,
        ),
      ],
    );
    return base;
  }
}
