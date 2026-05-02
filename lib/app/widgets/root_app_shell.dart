import 'package:animated_theme_switcher/animated_theme_switcher.dart'
    as animated_theme;
import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/cloud_sync_auth_flow_listener.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/widgets/cloud_sync_snapshot_sync_listener.dart';
import 'package:hoplixi/features/password_manager/close_store/close_store_sync_screen.dart';
import 'package:hoplixi/shared/widgets/desktop_shell.dart';
import 'package:universal_platform/universal_platform.dart';

import 'store_opening_overlay.dart';

class RootAppShell extends StatelessWidget {
  const RootAppShell({super.key, 
    required this.child,
    required this.isStoreOpeningOverlayVisible,
  });

  final Widget child;
  final bool isStoreOpeningOverlayVisible;

  @override
  Widget build(BuildContext context) {
    final appContent = Stack(
      children: [
        child,
        Positioned.fill(
          child: StoreOpeningOverlayHost(visible: isStoreOpeningOverlayVisible),
        ),
      ],
    );

    final appShell = UniversalPlatform.isDesktop
        ? RootBarsOverlay(child: appContent)
        : appContent;

    return CloudSyncSnapshotSyncListener(
      child: CloudSyncAuthFlowListener(
        child: animated_theme.ThemeSwitchingArea(
          child: CloseStoreSyncDialogHost(child: appShell),
        ),
      ),
    );
  }
}
