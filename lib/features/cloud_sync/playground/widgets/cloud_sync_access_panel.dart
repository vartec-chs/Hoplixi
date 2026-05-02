import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_actions.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_components.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncAccessPanel extends StatelessWidget {
  const CloudSyncAccessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return CloudSyncPanel(
      title: 'Управление доступом',
      icon: LucideIcons.shieldCheck,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactActionTile(
            icon: LucideIcons.keyRound,
            title: 'OAuth App Credentials',
            description:
                'Добавляйте client id/secret, выбирайте desktop/mobile target и храните пользовательские OAuth-приложения.',
            actionLabel: 'Открыть',
            onTap: () => openCloudSyncCredentials(context),
          ),
          const SizedBox(height: 10),
          _CompactActionTile(
            icon: LucideIcons.lockKeyhole,
            title: 'Auth Tokens',
            description:
                'Просматривайте подключённые аккаунты, refresh token и состояние сохранённых OAuth-токенов.',
            actionLabel: 'Открыть',
            onTap: () => openCloudSyncTokens(context),
          ),
        ],
      ),
    );
  }
}

class _CompactActionTile extends StatelessWidget {
  const _CompactActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.42),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onTap, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
