import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_state.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_status.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/providers/auth_flow_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/password_manager/store_settings/providers/store_settings_modal_provider.dart';
import 'package:hoplixi/features/password_manager/store_settings/store_settings_modal.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/global_key.dart';
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
  static const String _logTag = 'CloudSyncAuthFlowListener';

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

  Future<void> _handleTerminalState(AuthFlowState state) async {
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
        await ref.read(authTokensProvider.notifier).reload();
        await ref.read(currentStoreSyncProvider.notifier).loadStatus();
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
        logWarning(
          'Cloud sync auth terminal failure.',
          tag: _logTag,
          data: <String, dynamic>{
            'previousRoute': state.previousRoute,
            'provider': state.selectedProvider?.id,
            'credentialId': state.selectedCredentialId,
            'description': description,
          },
        );
        Toaster.error(
          title: l10n.failure_toast_title,
          description: description,
        );
        await _showErrorDialog(
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

    if (state.status == AuthFlowStatus.success) {
      _scheduleStoreSettingsReopenIfNeeded(targetRoute);
    } else {
      ref.read(pendingStoreSettingsModalPageProvider.notifier).clear();
    }

    ref.read(authFlowProvider.notifier).clearTerminalState();
  }

  void _scheduleStoreSettingsReopenIfNeeded(String targetRoute) {
    final initialPageIndex = ref.read(pendingStoreSettingsModalPageProvider);
    if (initialPageIndex == null ||
        !targetRoute.startsWith(AppRoutesPaths.dashboard)) {
      ref.read(pendingStoreSettingsModalPageProvider.notifier).clear();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final dialogContext =
          navigatorKey.currentState?.overlay?.context ??
          navigatorKey.currentContext;
      if (dialogContext == null) {
        ref.read(pendingStoreSettingsModalPageProvider.notifier).clear();
        return;
      }

      await showStoreSettingsModal(
        dialogContext,
        
        initialPageIndex: initialPageIndex,
      );
    });
  }

  Future<void> _showErrorDialog({
    required String title,
    required String description,
  }) async {
    final dialogContext =
        navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (dialogContext == null) {
      logWarning(
        'Skipping auth error dialog because no Navigator context is available.',
        tag: _logTag,
        data: <String, dynamic>{'title': title},
      );
      return;
    }

    await showDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (context) {
        final material = MaterialLocalizations.of(context);
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(child: SelectableText(description)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text(material.okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
