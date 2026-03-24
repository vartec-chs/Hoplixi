import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_state.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_status.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/routing/router.dart';

class CloudSyncAuthFlowListener extends ConsumerStatefulWidget {
  const CloudSyncAuthFlowListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloudSyncAuthFlowListener> createState() =>
      _CloudSyncAuthFlowListenerState();
}

class _CloudSyncAuthFlowListenerState
    extends ConsumerState<CloudSyncAuthFlowListener> {
  ProviderSubscription<AuthFlowState>? _subscription;
  AuthFlowStatus? _handledTerminalStatus;
  String? _handledPreviousRoute;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AuthFlowState>(authFlowProvider, (
      previous,
      next,
    ) {
      if (!_isTerminal(next.status)) {
        _handledTerminalStatus = null;
        _handledPreviousRoute = null;
        return;
      }

      final alreadyHandled =
          _handledTerminalStatus == next.status &&
          _handledPreviousRoute == next.previousRoute;
      if (alreadyHandled) {
        return;
      }

      _handledTerminalStatus = next.status;
      _handledPreviousRoute = next.previousRoute;

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
          description:
              state.error?.maybeMap(
                cancelled: (value) => value.message,
                orElse: () => null,
              ) ??
              l10n.cancel_toast_description,
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
    final router = ref.read(routerProvider);

    if (router.state.matchedLocation != targetRoute) {
      router.go(targetRoute);
    }

    ref.read(authFlowProvider.notifier).clearTerminalState();
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
