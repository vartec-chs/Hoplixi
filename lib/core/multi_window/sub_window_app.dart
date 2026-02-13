import 'dart:async';

import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/theme/theme_provider.dart';
import 'package:hoplixi/core/theme/theme_window_sync_service.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/shared/widgets/titlebar.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';

import 'sub_window_type.dart';

/// Виджет-обёртка для суб-окна.
///
/// Оборачивает содержимое суб-окна в [MaterialApp] с темой
/// приложения и [ToastificationWrapper] для показа тостов.
///
/// Использует глобальный [navigatorKey], чтобы [Toaster]
/// мог показывать тосты без явного контекста.
class SubWindowApp extends ConsumerStatefulWidget {
  /// Тип открываемого суб-окна (определяет заголовок).
  final SubWindowType type;

  /// Виджет содержимого окна.
  final Widget child;

  const SubWindowApp({super.key, required this.type, required this.child});

  @override
  ConsumerState<SubWindowApp> createState() => _SubWindowAppState();
}

class _SubWindowAppState extends ConsumerState<SubWindowApp> {
  ProviderSubscription<AsyncValue<ThemeMode>>? _themeSyncSubscription;

  @override
  void initState() {
    super.initState();

    unawaited(
      ThemeWindowSyncService.instance.bindSubNotifier(
        ref.read(themeProvider.notifier),
      ),
    );

    _themeSyncSubscription = ref.listenManual<AsyncValue<ThemeMode>>(
      themeProvider,
      (previous, next) {
        final mode = next.value;
        if (mode == null) return;
        if (ThemeWindowSyncService.instance.consumeSuppressedOutboundFlag(mode)) {
          return;
        }
        unawaited(ThemeWindowSyncService.instance.broadcastFromSub(mode));
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _themeSyncSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final themeMode = theme.value ?? ThemeMode.system;

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
          title: widget.type.title,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.light(context),
          darkTheme: AppTheme.dark(context),
          themeMode: themeMode,
          home: Scaffold(
            body: Column(
              children: [
                TitleBar(
                  labelOverride: widget.type.title,
                  showDatabaseButton: false,
                  showThemeSwitcher: false,
                  lockStoreOnClose: false,
                  onClose: () => windowManager.close(),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
