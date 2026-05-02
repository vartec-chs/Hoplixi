import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_auth_failure.freezed.dart';

@freezed
sealed class LocalAuthFailure with _$LocalAuthFailure implements Exception {
  const LocalAuthFailure._();

  const factory LocalAuthFailure.canceled() = _Canceled;
  const factory LocalAuthFailure.notAvailable() = _NotAvailable;
  const factory LocalAuthFailure.notEnrolled() = _NotEnrolled;
  const factory LocalAuthFailure.lockedOut() = _LockedOut;
  const factory LocalAuthFailure.permanentlyLockedOut() = _PermanentlyLockedOut;
  const factory LocalAuthFailure.other(String message) = _Other;
}
