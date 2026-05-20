import 'dart:typed_data';

import '../../../tables/otp/otp_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class OtpHistoryPayload extends HistoryPayload {
  const OtpHistoryPayload({
    this.otpType,
    this.issuer,
    this.accountName,
    this.secret,
    this.algorithm,
    this.digits,
    this.period,
    this.counter,
  });

  final OtpType? otpType;
  final String? issuer;
  final String? accountName;
  final Uint8List? secret;
  final OtpHashAlgorithm? algorithm;
  final int? digits;
  final int? period;
  final int? counter;

  @override
  VaultItemType get type => VaultItemType.otp;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'otp.otpType',
        label: 'Type',
        value: otpType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'otp.issuer',
        label: 'Issuer',
        value: issuer,
      ),
      HistoryFieldSnapshot<String>(
        key: 'otp.accountName',
        label: 'Account name',
        value: accountName,
      ),
      HistoryFieldSnapshot<Uint8List>(
        key: 'otp.secret',
        label: 'Secret',
        value: secret,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'otp.algorithm',
        label: 'Algorithm',
        value: algorithm?.name,
      ),
      HistoryFieldSnapshot<int>(
        key: 'otp.digits',
        label: 'Digits',
        value: digits,
      ),
      HistoryFieldSnapshot<int>(
        key: 'otp.period',
        label: 'Period',
        value: period,
      ),
      HistoryFieldSnapshot<int>(
        key: 'otp.counter',
        label: 'Counter',
        value: counter,
      ),
    ];
  }
}
