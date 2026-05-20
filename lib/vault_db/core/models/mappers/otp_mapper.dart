import 'package:hoplixi/vault_db/core/models/dto/otp_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension OtpItemsDataMapper on OtpItemsData {
  OtpDataDto toOtpDataDto() {
    return OtpDataDto(
      secret: secret,
      issuer: issuer,
      accountName: accountName,
      algorithm: algorithm,
      digits: digits,
      period: period,
      type: type,
      counter: counter,
    );
  }

  OtpCardDataDto toOtpCardDataDto() {
    return OtpCardDataDto(
      issuer: issuer,
      accountName: accountName,
      type: type,
      hasSecret: secret.isNotEmpty,
    );
  }
}
