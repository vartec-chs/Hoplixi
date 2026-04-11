import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/providers/app_credentials_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_credential_option.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_state.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_status.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_method.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth/services/cloud_sync_auth_service.dart';
import 'package:hoplixi/features/cloud_sync/auth/utils/cloud_sync_auth_credential_support.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

final cloudSyncAuthServiceProvider = Provider<CloudSyncAuthService>((ref) {
  final service = CloudSyncAuthService(getIt<HiveBoxManager>());
  ref.onDispose(() {
    service.dispose().ignore();
  });
  return service;
});

final authFlowProvider = NotifierProvider<AuthFlowNotifier, AuthFlowState>(
  AuthFlowNotifier.new,
);

final cloudSyncSupportedAuthProvidersProvider =
    Provider<List<CloudSyncProvider>>((ref) => getSupportedAuthProviders());

final authCredentialOptionsProvider = Provider<List<AuthCredentialOption>>((
  ref,
) {
  final selectedProvider = ref.watch(
    authFlowProvider.select((state) => state.selectedProvider),
  );
  if (selectedProvider == null) {
    return const <AuthCredentialOption>[];
  }

  final entries =
      ref.watch(appCredentialsProvider).value ?? const <AppCredentialEntry>[];
  final filtered = entries
      .where((entry) => entry.provider == selectedProvider)
      .map(buildAuthCredentialOption)
      .toList(growable: false);
  filtered.sort((left, right) {
    final builtinCompare = right.entry.isBuiltin == left.entry.isBuiltin
        ? 0
        : (left.entry.isBuiltin ? -1 : 1);
    if (builtinCompare != 0) {
      return builtinCompare;
    }
    return left.entry.name.toLowerCase().compareTo(
      right.entry.name.toLowerCase(),
    );
  });
  return filtered;
});

class AuthFlowNotifier extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  void startFlow({required String previousRoute}) {
    state = AuthFlowState(
      status: AuthFlowStatus.selectingProvider,
      previousRoute: previousRoute,
    );
  }

  void selectProvider(CloudSyncProvider provider) {
    state = state.copyWith(
      status: AuthFlowStatus.selectingCredential,
      selectedProvider: provider,
      selectedCredentialId: null,
      selectedCredentialName: null,
      savedTokenId: null,
      savedToken: null,
      error: null,
      isCancellable: false,
    );
  }

  Future<void> selectCredential(String credentialId) async {
    final credential = await _loadCredential(credentialId);
    if (credential == null) {
      _setError(
        const CloudSyncAuthError.unsupportedCredential(
          message: 'Selected credential was not found.',
        ),
      );
      return;
    }

    state = state.copyWith(
      status: AuthFlowStatus.selectingCredential,
      selectedProvider: credential.provider,
      selectedCredentialId: credential.id,
      selectedCredentialName: credential.name,
      savedTokenId: null,
      savedToken: null,
      error: null,
      isCancellable: false,
    );
  }

  Future<void> beginAuthorization({
    CloudSyncAuthMethod method = CloudSyncAuthMethod.automatic,
    String? manualAuthorizationCode,
  }) async {
    final credentialId = state.selectedCredentialId;
    if (credentialId == null) {
      _setError(
        const CloudSyncAuthError.unsupportedCredential(
          message: 'Select an app credential before authorization.',
        ),
      );
      return;
    }

    state = state.copyWith(
      status: AuthFlowStatus.inProgress,
      error: null,
      isCancellable: true,
      savedTokenId: null,
      savedToken: null,
    );

    unawaited(
      _executeAuthorization(
        credentialId,
        method: method,
        manualAuthorizationCode: manualAuthorizationCode,
      ),
    );
  }

  Future<void> cancelActiveFlow() async {
    if (state.status != AuthFlowStatus.inProgress) {
      return;
    }

    await ref.read(cloudSyncAuthServiceProvider).cancelActiveFlow();
    state = state.copyWith(
      status: AuthFlowStatus.cancelled,
      isCancellable: false,
      error: const CloudSyncAuthError.cancelled(
        message: 'Authorization was cancelled by the user.',
      ),
    );
  }

  void clearTerminalState() {
    state = const AuthFlowState();
  }

  Future<void> _executeAuthorization(
    String credentialId, {
    CloudSyncAuthMethod method = CloudSyncAuthMethod.automatic,
    String? manualAuthorizationCode,
  }) async {
    final credential = await _loadCredential(credentialId);
    if (credential == null) {
      _setError(
        const CloudSyncAuthError.unsupportedCredential(
          message: 'Selected credential was not found.',
        ),
      );
      return;
    }

    try {
      final result = await ref
          .read(cloudSyncAuthServiceProvider)
          .authorize(
            credential: credential,
            method: method,
            manualAuthorizationCode: manualAuthorizationCode,
          );
      state = state.copyWith(
        status: AuthFlowStatus.success,
        selectedProvider: credential.provider,
        selectedCredentialId: credential.id,
        selectedCredentialName: credential.name,
        savedTokenId: result.savedTokenId,
        savedToken: result.savedToken,
        error: null,
        isCancellable: false,
      );
    } catch (error) {
      final mappedError = ref
          .read(cloudSyncAuthServiceProvider)
          .mapError(error);
      _setError(mappedError);
    }
  }

  void _setError(CloudSyncAuthError error) {
    state = state.copyWith(
      status: error.when(
        cancelled: (_) => AuthFlowStatus.cancelled,
        unsupportedCredential: (_) => AuthFlowStatus.failure,
        misconfiguredRedirect: (_) => AuthFlowStatus.failure,
        oauthProvider: (_) => AuthFlowStatus.failure,
        network: (_) => AuthFlowStatus.failure,
        timeout: (_) => AuthFlowStatus.failure,
        unknown: (_) => AuthFlowStatus.failure,
      ),
      error: error,
      isCancellable: false,
    );
  }

  Future<AppCredentialEntry?> _loadCredential(String credentialId) async {
    final service = ref.read(appCredentialsServiceProvider);
    await service.initialize();
    return service.getById(credentialId);
  }
}
