import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_actions.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_components.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncPlaygroundHeader extends StatelessWidget {
  const CloudSyncPlaygroundHeader({super.key, this.isDesktop = false});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authL10n = context.t.cloud_sync_auth;

    return CloudSyncPanel(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CloudSyncIconBox(
                icon: LucideIcons.cloudCog,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                size: isDesktop ? 48 : 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Sync Center',
                      style:
                          (isDesktop
                                  ? theme.textTheme.headlineMedium
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Настройте OAuth App Credentials, подключите аккаунты и проверьте файловые операции Drive API в одном месте.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 22 : 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SmoothButton(
                label: authL10n.launch_action_label,
                icon: const Icon(LucideIcons.logIn, size: 18),
                onPressed: () => openCloudSyncAuthSheet(context),
              ),
              SmoothButton(
                label: 'App Credentials',
                type: SmoothButtonType.tonal,
                icon: const Icon(LucideIcons.keyRound, size: 18),
                onPressed: () => openCloudSyncCredentials(context),
              ),
              SmoothButton(
                label: 'Токены',
                type: SmoothButtonType.outlined,
                icon: const Icon(LucideIcons.lockKeyhole, size: 18),
                onPressed: () => openCloudSyncTokens(context),
              ),
              SmoothButton(
                label: 'Storage API',
                type: SmoothButtonType.outlined,
                icon: const Icon(LucideIcons.folderCog, size: 18),
                onPressed: () => openCloudSyncStorage(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
