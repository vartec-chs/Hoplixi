import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/providers/app_credentials_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_credential_option.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_status.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/auth_credential_list_tile.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/auth_provider_list_tile.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

Future<void> showCloudSyncAuthSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String previousRoute,
  CloudSyncProvider? initialProvider,
}) async {
  final rootContext = context;
  final notifier = ref.read(authFlowProvider.notifier);
  notifier.startFlow(previousRoute: previousRoute);
  if (initialProvider != null) {
    notifier.selectProvider(initialProvider);
  }

  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    pageListBuilder: (modalContext) => initialProvider == null
        ? [
            WoltModalSheetPage(
              topBarTitle: Text(rootContext.t.cloud_sync_auth.modal_title),
              hasTopBarLayer: true,
              isTopBarLayerAlwaysVisible: true,
              trailingNavBarWidget: IconButton(
                onPressed: () => Navigator.of(modalContext).pop(),
                icon: const Icon(Icons.close),
                tooltip: rootContext.t.cloud_sync_auth.cancel_button,
              ),
              child: _ProviderSelectionStep(rootContext: rootContext),
            ),
            WoltModalSheetPage(
              topBarTitle: Text(rootContext.t.cloud_sync_auth.modal_title),
              hasTopBarLayer: true,
              isTopBarLayerAlwaysVisible: true,
              leadingNavBarWidget: IconButton(
                onPressed: WoltModalSheet.of(modalContext).showPrevious,
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(
                  rootContext,
                ).backButtonTooltip,
              ),
              trailingNavBarWidget: IconButton(
                onPressed: () => Navigator.of(modalContext).pop(),
                icon: const Icon(Icons.close),
                tooltip: rootContext.t.cloud_sync_auth.cancel_button,
              ),
              child: _CredentialSelectionStep(
                rootContext: rootContext,
                modalContext: modalContext,
              ),
            ),
          ]
        : [
            WoltModalSheetPage(
              topBarTitle: Text(rootContext.t.cloud_sync_auth.modal_title),
              hasTopBarLayer: true,
              isTopBarLayerAlwaysVisible: true,
              trailingNavBarWidget: IconButton(
                onPressed: () => Navigator.of(modalContext).pop(),
                icon: const Icon(Icons.close),
                tooltip: rootContext.t.cloud_sync_auth.cancel_button,
              ),
              child: _CredentialSelectionStep(
                rootContext: rootContext,
                modalContext: modalContext,
              ),
            ),
          ],
  );

  final status = ref.read(authFlowProvider).status;
  if (status == AuthFlowStatus.selectingProvider ||
      status == AuthFlowStatus.selectingCredential) {
    ref.read(authFlowProvider.notifier).clearTerminalState();
  }
}

class _ProviderSelectionStep extends ConsumerWidget {
  const _ProviderSelectionStep({required this.rootContext});

  final BuildContext rootContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = rootContext.t.cloud_sync_auth;
    final providers = ref.watch(cloudSyncSupportedAuthProvidersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.provider_step_title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          InfoNotificationCard(text: l10n.provider_step_description),
          const SizedBox(height: 16),
          for (final provider in providers) ...[
            AuthProviderListTile(
              provider: provider,
              onTap: () {
                ref.read(authFlowProvider.notifier).selectProvider(provider);
                WoltModalSheet.of(context).showNext();
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CredentialSelectionStep extends ConsumerWidget {
  const _CredentialSelectionStep({
    required this.rootContext,
    required this.modalContext,
  });

  final BuildContext rootContext;
  final BuildContext modalContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = rootContext.t.cloud_sync_auth;
    final selectedProvider = ref.watch(
      authFlowProvider.select((state) => state.selectedProvider),
    );
    final asyncCredentials = ref.watch(appCredentialsProvider);
    final credentialOptions = ref.watch(authCredentialOptionsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.credential_step_title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          InfoNotificationCard(text: l10n.credential_step_description),
          const SizedBox(height: 16),
          if (selectedProvider != null)
            Text(
              selectedProvider.metadata.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          asyncCredentials.when(
            data: (_) {
              if (credentialOptions.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WarningNotificationCard(text: l10n.no_credentials_message),
                    const SizedBox(height: 16),
                    SmoothButton(
                      label: l10n.open_credentials_button,
                      onPressed: () {
                        Navigator.of(modalContext).pop();
                        rootContext.go(AppRoutesPaths.cloudSyncAppCredentials);
                      },
                    ),
                  ],
                );
              }

              final builtin = credentialOptions
                  .where((option) => option.entry.isBuiltin)
                  .toList(growable: false);
              final custom = credentialOptions
                  .where((option) => !option.entry.isBuiltin)
                  .toList(growable: false);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (builtin.isNotEmpty) ...[
                    Text(
                      l10n.built_in_section_title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._buildCredentialTiles(
                      options: builtin,
                      ref: ref,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (custom.isNotEmpty) ...[
                    Text(
                      l10n.custom_section_title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._buildCredentialTiles(
                      options: custom,
                      ref: ref,
                      l10n: l10n,
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ErrorNotificationCard(text: l10n.load_credentials_error),
                const SizedBox(height: 16),
                SmoothButton(
                  label: l10n.retry_button,
                  onPressed: () {
                    ref.read(appCredentialsProvider.notifier).reload();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCredentialTiles({
    required List<AuthCredentialOption> options,
    required WidgetRef ref,
    required dynamic l10n,
  }) {
    return options
        .map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AuthCredentialListTile(
              option: option,
              builtinLabel: l10n.credential_builtin_badge,
              customLabel: l10n.credential_custom_badge,
              unavailableReason: _resolveSupportIssueMessage(
                option.supportIssue,
                l10n,
              ),
              onTap: option.isSupported
                  ? () async {
                      await ref
                          .read(authFlowProvider.notifier)
                          .selectCredential(option.entry.id);
                      await ref
                          .read(authFlowProvider.notifier)
                          .beginAuthorization();
                      Navigator.of(modalContext).pop();
                    }
                  : null,
            ),
          ),
        )
        .toList(growable: false);
  }

  String? _resolveSupportIssueMessage(
    AuthCredentialSupportIssue? issue,
    dynamic l10n,
  ) {
    return switch (issue) {
      AuthCredentialSupportIssue.unsupportedProvider =>
        l10n.unsupported_provider_message,
      AuthCredentialSupportIssue.missingProviderConfig =>
        l10n.unsupported_provider_message,
      AuthCredentialSupportIssue.mobileDropboxRequiresBuiltin =>
        l10n.unsupported_dropbox_mobile_message,
      AuthCredentialSupportIssue.mobilePlatformUnsupported =>
        l10n.unsupported_mobile_message,
      null => null,
    };
  }
}
