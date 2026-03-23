import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

/// Подсказки по настройке OAuth-приложения для выбранного провайдера.
class AppCredentialSetupInfoCard extends StatelessWidget {
  const AppCredentialSetupInfoCard({super.key, required this.provider});

  final CloudSyncProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_app_credentials;
    final metadata = provider.metadata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoNotificationCard(text: l10n.setup_info_description),
        if (provider == CloudSyncProvider.dropbox) ...[
          const SizedBox(height: 12),
          WarningNotificationCard(text: l10n.dropbox_redirect_hint),
        ],
        if (provider == CloudSyncProvider.onedrive) ...[
          const SizedBox(height: 12),
          WarningNotificationCard(text: l10n.onedrive_redirect_hint),
        ],
        const SizedBox(height: 12),
        _CopyableValueTile(
          label: l10n.desktop_redirect_label,
          value: metadata.desktopRedirectUri,
        ),
        const SizedBox(height: 12),
        _CopyableValueTile(
          label: l10n.mobile_redirect_label,
          value: metadata.appCredentialsMobileRedirectUri,
        ),
        if (metadata.scopes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CopyableValueTile(
            label: l10n.scopes_label,
            value: metadata.scopes.join('\n'),
          ),
        ],
      ],
    );
  }
}

class _CopyableValueTile extends StatelessWidget {
  const _CopyableValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.t.cloud_sync_app_credentials;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            Toaster.success(
              title: l10n.copy_success_title,
              description: l10n.copy_success_description(Field: label),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.copy_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
