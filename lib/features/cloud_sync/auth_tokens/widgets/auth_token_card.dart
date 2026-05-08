import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:intl/intl.dart';

/// Карточка токена в списке auth tokens.
class AuthTokenCard extends StatelessWidget {
  const AuthTokenCard({super.key, required this.token, required this.onTap});

  final AuthTokenEntry token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_auth_tokens;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expiresLabel = token.expiresAt == null
        ? l10n.no_expiry_value
        : l10n.expires_at_value(
            Value: DateFormat.yMMMd().add_Hm().format(token.expiresAt!),
          );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: CloudSyncProviderLogo(
                      metadata: token.provider.metadata,
                      size: 28,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        token.displayLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        token.provider.metadata.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expiresLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusChip(
                      label: token.isExpired
                          ? l10n.expired_badge
                          : l10n.active_badge,
                      color: token.isExpired
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    if (token.hasRefreshToken) ...[
                      const SizedBox(height: 6),
                      _StatusChip(
                        label: l10n.refresh_token_badge,
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
