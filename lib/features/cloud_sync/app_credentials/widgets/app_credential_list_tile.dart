import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

/// Карточка одной записи app credentials.
class AppCredentialListTile extends StatelessWidget {
  const AppCredentialListTile({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  final AppCredentialEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_app_credentials;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: entry.isBuiltin ? null : onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Center(
            child: CloudSyncProviderLogo(
              metadata: entry.provider.metadata,
              size: 24,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(entry.name)),
            const SizedBox(width: 8),
            _Badge(
              label: entry.isBuiltin ? l10n.builtin_badge : l10n.custom_badge,
              icon: entry.isBuiltin ? Icons.lock_outline : Icons.edit_outlined,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.provider.metadata.displayName),
              const SizedBox(height: 4),
              Text(
                l10n.client_id_value(Value: _maskClientId(entry.clientId)),
                style: theme.textTheme.bodySmall,
              ),
              if (entry.clientSecret != null) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.client_secret_present,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        trailing: entry.isBuiltin
            ? Icon(Icons.lock_outline, color: theme.colorScheme.outline)
            : PopupMenuButton<_AppCredentialAction>(
                onSelected: (action) {
                  switch (action) {
                    case _AppCredentialAction.edit:
                      onEdit?.call();
                      return;
                    case _AppCredentialAction.delete:
                      onDelete?.call();
                      return;
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<_AppCredentialAction>(
                      value: _AppCredentialAction.edit,
                      child: Text(l10n.edit_action),
                    ),
                    PopupMenuItem<_AppCredentialAction>(
                      value: _AppCredentialAction.delete,
                      child: Text(l10n.delete_action),
                    ),
                  ];
                },
              ),
      ),
    );
  }

  String _maskClientId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}

enum _AppCredentialAction { edit, delete }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
