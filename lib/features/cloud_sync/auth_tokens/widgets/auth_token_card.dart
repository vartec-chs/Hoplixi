import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:intl/intl.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';

/// Карточка токена в списке auth tokens.
class AuthTokenCard extends StatelessWidget {
  const AuthTokenCard({super.key, required this.token, required this.onTap});

  final AuthTokenEntry token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_auth_tokens;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            token.provider.metadata.icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(token.displayLabel),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(token.provider.metadata.displayName),
              const SizedBox(height: 4),
              Text(
                token.expiresAt == null
                    ? l10n.no_expiry_value
                    : l10n.expires_at_value(
                        Value: DateFormat.yMMMd().add_Hm().format(
                          token.expiresAt!,
                        ),
                      ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusChip(
              label: token.isExpired ? l10n.expired_badge : l10n.active_badge,
              color: token.isExpired
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            if (token.hasRefreshToken) ...[
              const SizedBox(height: 6),
              _StatusChip(
                label: l10n.refresh_token_badge,
                color: theme.colorScheme.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
