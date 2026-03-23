import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_state.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_status.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

class AuthProgressScreen extends ConsumerStatefulWidget {
  const AuthProgressScreen({super.key});

  @override
  ConsumerState<AuthProgressScreen> createState() => _AuthProgressScreenState();
}

class _AuthProgressScreenState extends ConsumerState<AuthProgressScreen> {
  ProviderSubscription<AuthFlowState>? _subscription;
  AuthFlowStatus? _handledTerminalStatus;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AuthFlowState>(authFlowProvider, (
      previous,
      next,
    ) {
      if (!_isTerminal(next.status) || _handledTerminalStatus == next.status) {
        return;
      }
      _handledTerminalStatus = next.status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTerminalState(next);
      });
    }, fireImmediately: true);
  }

  bool _isTerminal(AuthFlowStatus status) {
    return status == AuthFlowStatus.success ||
        status == AuthFlowStatus.cancelled ||
        status == AuthFlowStatus.failure;
  }

  void _handleTerminalState(AuthFlowState state) {
    if (!mounted) {
      return;
    }

    final l10n = context.t.cloud_sync_auth;
    final description =
        state.error?.map(
          cancelled: (value) => value.message,
          unsupportedCredential: (value) => value.message,
          misconfiguredRedirect: (value) => value.message,
          oauthProvider: (value) => value.message,
          network: (value) => value.message,
          timeout: (value) => value.message,
          unknown: (value) => value.message,
        ) ??
        l10n.failure_fallback_description;

    switch (state.status) {
      case AuthFlowStatus.success:
        Toaster.success(
          title: l10n.success_toast_title,
          description: l10n.success_toast_description,
        );
      case AuthFlowStatus.cancelled:
        Toaster.info(
          title: l10n.cancel_toast_title,
          description: l10n.cancel_toast_description,
        );
      case AuthFlowStatus.failure:
        Toaster.error(
          title: l10n.failure_toast_title,
          description: description,
        );
      case AuthFlowStatus.idle:
      case AuthFlowStatus.selectingProvider:
      case AuthFlowStatus.selectingCredential:
      case AuthFlowStatus.inProgress:
        return;
    }

    final targetRoute = state.previousRoute ?? AppRoutesPaths.home;
    ref.read(authFlowProvider.notifier).clearTerminalState();
    context.go(targetRoute);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

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
