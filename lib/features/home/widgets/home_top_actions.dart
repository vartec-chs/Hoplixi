import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/about/ui/about_app_modal.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:universal_platform/universal_platform.dart';

class HomeTopActions extends StatelessWidget {
  const HomeTopActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: UniversalPlatform.isMobile ? MediaQuery.of(context).padding.top : 36,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            color: Colors.white.withOpacity(0.8),
            tooltip: 'Настройки',
            onPressed: () => context.push(AppRoutesPaths.settings),
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
}
