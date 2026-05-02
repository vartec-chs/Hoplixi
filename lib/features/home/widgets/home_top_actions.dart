import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/about/ui/about_app_modal.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:universal_platform/universal_platform.dart';

class HomeTopActions extends StatelessWidget {
  const HomeTopActions({
    super.key,
    this.settingsShowcaseKey,
    this.showcaseScope,
    this.helpButton,
  });

  final GlobalKey? settingsShowcaseKey;
  final String? showcaseScope;
  final Widget? helpButton;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: UniversalPlatform.isMobile ? MediaQuery.of(context).padding.top : 36,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (helpButton != null) helpButton!,
          _wrapSettingsButton(
            context,
            IconButton(
              icon: const Icon(LucideIcons.settings),
              color: Colors.white.withOpacity(0.8),
              tooltip: 'Настройки',
              onPressed: () => context.push(AppRoutesPaths.settings),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: Colors.white.withOpacity(0.8),
            tooltip: 'О приложении',
            onPressed: () => showAppAboutModal(context),
          ),
        ],
      ),
    );
  }

  Widget _wrapSettingsButton(BuildContext context, Widget child) {
    final showcaseKey = settingsShowcaseKey;
    if (showcaseKey == null) {
      return child;
    }

    return Showcase(
      key: showcaseKey,
      scope: showcaseScope,
      title: 'Настройки приложения',
      description:
          'Здесь находятся параметры интерфейса, безопасности и поведения приложения.',
      child: child,
    );
  }
}
