import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_flow_status.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/cloud_sync_auth_error.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

part 'auth_flow_state.freezed.dart';
part 'auth_flow_state.g.dart';

@freezed
sealed class AuthFlowState with _$AuthFlowState {
  const factory AuthFlowState({
    @Default(AuthFlowStatus.idle) AuthFlowStatus status,
    String? previousRoute,
    CloudSyncProvider? selectedProvider,
    String? selectedCredentialId,
    String? selectedCredentialName,
    String? savedTokenId,
    AuthTokenEntry? savedToken,
    CloudSyncAuthError? error,
    @Default(false) bool isCancellable,
  }) = _AuthFlowState;

  factory AuthFlowState.fromJson(Map<String, dynamic> json) =>
      _$AuthFlowStateFromJson(json);
}
