import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_components.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CloudSyncHealthPanel extends StatelessWidget {
  const CloudSyncHealthPanel({
    super.key,
    required this.credentialsAsync,
    required this.tokensAsync,
  });

  final AsyncValue<List<AppCredentialEntry>> credentialsAsync;
  final AsyncValue<List<AuthTokenEntry>> tokensAsync;

  @override
  Widget build(BuildContext context) {
    final credentials = credentialsAsync.value ?? const [];
    final tokens = tokensAsync.value ?? const [];
    final customCredentials = credentials.where((entry) => !entry.isBuiltin);
    final expiredTokens = tokens.where((token) => token.isExpired);
    final refreshableTokens = tokens.where((token) => token.hasRefreshToken);

    return CloudSyncPanel(
      title: 'Состояние подключения',
      icon: LucideIcons.activity,
      child: Column(
        children: [
          _MetricRow(
            icon: LucideIcons.keyRound,
            label: 'App Credentials',
            value: asyncCountLabel(credentialsAsync, credentials.length),
            helper: '${customCredentials.length} пользовательских',
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: LucideIcons.lockKeyhole,
            label: 'Auth Tokens',
            value: asyncCountLabel(tokensAsync, tokens.length),
            helper: '${refreshableTokens.length} с refresh token',
          ),
          const SizedBox(height: 12),
          _MetricRow(
            icon: expiredTokens.isEmpty
                ? LucideIcons.circleCheck
                : LucideIcons.circleAlert,
            label: 'Истёкшие токены',
            value: asyncCountLabel(tokensAsync, expiredTokens.length),
            helper: expiredTokens.isEmpty
                ? 'Критичных действий нет'
                : 'Нужна повторная авторизация',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                helper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
