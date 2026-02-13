import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/global_key.dart';
import 'package:toastification/toastification.dart';

import 'sub_window_type.dart';

/// Виджет-обёртка для суб-окна.
///
/// Оборачивает содержимое суб-окна в [MaterialApp] с темой
/// приложения и [ToastificationWrapper] для показа тостов.
///
/// Использует глобальный [navigatorKey], чтобы [Toaster]
/// мог показывать тосты без явного контекста.
class SubWindowApp extends StatelessWidget {
  /// Тип открываемого суб-окна (определяет заголовок).
  final SubWindowType type;

  /// Виджет содержимого окна.
  final Widget child;

  const SubWindowApp({super.key, required this.type, required this.child});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: const ToastificationConfig(
        maxTitleLines: 2,
        clipBehavior: Clip.hardEdge,
        maxDescriptionLines: 5,
        maxToastLimit: 3,
        itemWidth: 360,
        alignment: Alignment.bottomRight,
      ),
      child: animated_theme.ThemeProvider(
        initTheme: AppTheme.dark(context),
        child: MaterialApp(
          title: type.title,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.light(context),
          darkTheme: AppTheme.dark(context),
          themeMode: ThemeMode.system,
          home: Scaffold(
            appBar: AppBar(
              title: Text(type.title),
              centerTitle: true,
              toolbarHeight: 40,
              titleTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            body: child,
          ),
        ),
      ),
    );
  }
}
