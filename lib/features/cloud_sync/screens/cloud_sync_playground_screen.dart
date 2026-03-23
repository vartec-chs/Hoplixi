import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncPlaygroundScreen extends ConsumerWidget {
  const CloudSyncPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authL10n = context.t.cloud_sync_auth;

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CloudSyncActionCard(
            icon: LucideIcons.cloud,
            title: authL10n.launch_action_label,
            description: authL10n.launch_action_description,
            onTap: () async {
              await showCloudSyncAuthSheet(
                context: context,
                ref: ref,
                previousRoute: AppRoutesPaths.cloudSync,
              );
            },
          ),
          const SizedBox(height: 12),
          _CloudSyncActionCard(
            icon: LucideIcons.keyRound,
            title: 'OAuth App Credentials',
            description:
                'Встроенные и пользовательские OAuth-приложения для cloud sync.',
            onTap: () => context.push(AppRoutesPaths.cloudSyncAppCredentials),
          ),
          const SizedBox(height: 12),
          _CloudSyncActionCard(
            icon: LucideIcons.lock,
            title: 'Auth Tokens',
            description:
                'Сохранённые access/refresh токены, полученные после авторизации.',
            onTap: () => context.push(AppRoutesPaths.cloudSyncAuthTokens),
          ),
          const SizedBox(height: 12),
          _CloudSyncActionCard(
            icon: LucideIcons.folderCog,
            title: 'Storage Layer',
            description:
                'Низкоуровневый storage-слой уже подключён в кодовую базу. UI для него пока не добавлен.',
          ),
        ],
      ),
    );
  }
}

class _CloudSyncActionCard extends StatelessWidget {
  const _CloudSyncActionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 12),
                Icon(
                  LucideIcons.chevronRight,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
