import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/modal_sheet_close_button.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// Открывает sheet с деталями токена.
Future<void> showAuthTokenDetailsSheet({
  required BuildContext context,
  required AuthTokenEntry token,
  required Future<void> Function() onDelete,
}) async {
  await WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalContext) {
      return [_buildPage(modalContext, token: token, onDelete: onDelete)];
    },
  );
}

SliverWoltModalSheetPage _buildPage(
  BuildContext context, {
  required AuthTokenEntry token,
  required Future<void> Function() onDelete,
}) {
  final l10n = context.t.cloud_sync_auth_tokens;

  return SliverWoltModalSheetPage(
    pageTitle: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(l10n.details_title),
    ),
    leadingNavBarWidget: const ModalSheetCloseButton(),
    mainContentSliversBuilder: (_) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverToBoxAdapter(
            child: _DetailsContent(token: token, onDelete: onDelete),
          ),
        ),
      ];
    },
  );
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({required this.token, required this.onDelete});

  final AuthTokenEntry token;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_auth_tokens;
    final extraJson = token.extraData.isEmpty
        ? l10n.no_extra_data_value
        : const JsonEncoder.withIndent('  ').convert(token.extraData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CopyableField(
          label: l10n.provider_label,
          value: token.provider.metadata.displayName,
        ),
        if (token.appCredentialName != null) ...[
          const SizedBox(height: 12),
          _CopyableField(
            label: l10n.app_credential_label,
            value: token.appCredentialName!,
          ),
        ],
        if (token.accountName != null) ...[
          const SizedBox(height: 12),
          _CopyableField(
            label: l10n.account_name_label,
            value: token.accountName!,
          ),
        ],
        if (token.accountEmail != null) ...[
          const SizedBox(height: 12),
          _CopyableField(
            label: l10n.account_email_label,
            value: token.accountEmail!,
          ),
        ],
        if (token.accountId != null) ...[
          const SizedBox(height: 12),
          _CopyableField(label: l10n.account_id_label, value: token.accountId!),
        ],
        if (token.tokenType != null) ...[
          const SizedBox(height: 12),
          _CopyableField(label: l10n.token_type_label, value: token.tokenType!),
        ],
        const SizedBox(height: 12),
        _CopyableField(
          label: l10n.expires_at_label,
          value: token.expiresAt?.toIso8601String() ?? l10n.no_expiry_value,
        ),
        const SizedBox(height: 12),
        _CopyableField(
          label: l10n.access_token_label,
          value: token.accessToken,
        ),
        const SizedBox(height: 12),
        _CopyableField(
          label: l10n.refresh_token_label,
          value: token.refreshToken ?? l10n.no_refresh_token_value,
        ),
        const SizedBox(height: 12),
        _CopyableField(
          label: l10n.scopes_label,
          value: token.scopes.isEmpty
              ? l10n.no_scopes_value
              : token.scopes.join('\n'),
        ),
        const SizedBox(height: 12),
        _CopyableField(label: l10n.extra_data_label, value: extraJson),
        const SizedBox(height: 20),
        SmoothButton(
          label: l10n.delete_button,
          variant: SmoothButtonVariant.error,
          onPressed: () async {
            await onDelete();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  const _CopyableField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.t.cloud_sync_auth_tokens;

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
