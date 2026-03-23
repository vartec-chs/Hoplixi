import 'package:flutter/material.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Пустое состояние списка токенов.
class AuthTokensEmptyState extends StatelessWidget {
  const AuthTokensEmptyState({super.key, required this.onReloadPressed});

  final VoidCallback onReloadPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_auth_tokens;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.empty_title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.empty_description,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SmoothButton(
            label: l10n.reload_button,
            type: SmoothButtonType.outlined,
            onPressed: onReloadPressed,
          ),
        ],
      ),
    );
  }
}
