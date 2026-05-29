import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/core/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto_history/recovery_codes_history_dto.dart';

extension RecoveryCodesItemsDataMapper on RecoveryCodesItemsData {
  RecoveryCodesDataDto toRecoveryCodesDataDto() {
    return RecoveryCodesDataDto(
      generatedAt: generatedAt,
      oneTime: oneTime,
    );
  }

  RecoveryCodesCardDataDto toRecoveryCodesCardDataDto() {
    return RecoveryCodesCardDataDto(
      generatedAt: generatedAt,
      oneTime: oneTime,
      hasCodes: false,
    );
  }
}

extension RecoveryCodeDataMapper on RecoveryCodeData {
  RecoveryCodeValueDto toRecoveryCodeValueDto() {
    return RecoveryCodeValueDto(
      id: id,
      code: code,
      used: used,
      usedAt: usedAt,
      position: position,
    );
  }

  RecoveryCodeValueCardDto toRecoveryCodeValueCardDto() {
    return RecoveryCodeValueCardDto(
      id: id,
      used: used,
      usedAt: usedAt,
      position: position,
      hasCode: code.isNotEmpty,
    );
  }
}

extension RecoveryCodesHistoryDataMapper on RecoveryCodesHistoryData {
  RecoveryCodesHistoryDataDto toRecoveryCodesHistoryDataDto() {
    return RecoveryCodesHistoryDataDto(
      generatedAt: generatedAt,
      oneTime: oneTime,
    );
  }

  RecoveryCodesHistoryCardDataDto toRecoveryCodesHistoryCardDataDto() {
    return RecoveryCodesHistoryCardDataDto(
      generatedAt: generatedAt,
      oneTime: oneTime,
    );
  }
}
