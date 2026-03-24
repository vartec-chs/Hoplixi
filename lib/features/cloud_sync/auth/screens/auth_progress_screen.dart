import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

class AuthProgressScreen extends ConsumerStatefulWidget {
  const AuthProgressScreen({super.key});

  @override
  ConsumerState<AuthProgressScreen> createState() => _AuthProgressScreenState();
}

class _AuthProgressScreenState extends ConsumerState<AuthProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.t.cloud_sync_auth;
    final state = ref.watch(authFlowProvider);
    final providerName = state.selectedProvider?.metadata.displayName ?? '-';
    final credentialName = state.selectedCredentialName ?? '-';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progress_title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 24),
                  InfoNotificationCard(text: l10n.progress_description),
                  const SizedBox(height: 16),
                  Text(
                    l10n.status_in_progress,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.progress_provider_label(Provider: providerName),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.progress_credential_label(Credential: credentialName),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SmoothButton(
                    label: l10n.cancel_button,
                    type: SmoothButtonType.outlined,
                    onPressed: state.isCancellable
                        ? () {
                            ref
                                .read(authFlowProvider.notifier)
                                .cancelActiveFlow();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
