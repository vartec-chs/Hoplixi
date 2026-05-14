import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/recovery_codes_dto.dart';

extension RecoveryCodesItemsDataMapper on RecoveryCodesItemsData {
  RecoveryCodesDataDto toRecoveryCodesDataDto() {
    return RecoveryCodesDataDto(
      codesCount: codesCount,
      usedCount: usedCount,
      generatedAt: generatedAt,
      oneTime: oneTime,
    );
  }

  RecoveryCodesCardDataDto toRecoveryCodesCardDataDto() {
    return RecoveryCodesCardDataDto(
      codesCount: codesCount,
      usedCount: usedCount,
      generatedAt: generatedAt,
      oneTime: oneTime,
    );
  }
}
