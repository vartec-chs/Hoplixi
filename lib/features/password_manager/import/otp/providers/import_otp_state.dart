import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/import/otp/otp_extractor.dart';

part 'import_otp_state.freezed.dart';

@freezed
sealed class ImportOtpState with _$ImportOtpState {
  const factory ImportOtpState({
    @Default([]) List<OtpData> importedOtps,
    @Default({}) Set<int> selectedIndices,
    @Default({}) Set<int> expandedIndices,
    @Default(false) bool isSaving,
    @Default(30) int remainingSeconds,
  }) = _ImportOtpState;
}
