import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';

part 'auth_flow_success_result.freezed.dart';
part 'auth_flow_success_result.g.dart';

@freezed
sealed class AuthFlowSuccessResult with _$AuthFlowSuccessResult {
  const factory AuthFlowSuccessResult({
    required String savedTokenId,
    required AuthTokenEntry savedToken,
  }) = _AuthFlowSuccessResult;

  factory AuthFlowSuccessResult.fromJson(Map<String, dynamic> json) =>
      _$AuthFlowSuccessResultFromJson(json);
}
