import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/main_db/core/models/dto/recovery_codes_history_dto.dart';

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
      hasCodes: codesCount > 0,
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
      codesCount: codesCount,
      usedCount: usedCount,
      generatedAt: generatedAt,
      oneTime: oneTime,
    );
  }

  RecoveryCodesHistoryCardDataDto toRecoveryCodesHistoryCardDataDto({
    required bool hasCodeValues,
  }) {
    return RecoveryCodesHistoryCardDataDto(
      codesCount: codesCount,
      usedCount: usedCount,
      generatedAt: generatedAt,
      oneTime: oneTime,
      hasCodeValues: hasCodeValues,
    );
  }
}

extension RecoveryCodeValuesHistoryDataMapper on RecoveryCodeValuesHistoryData {
  RecoveryCodeValueHistoryDataDto toRecoveryCodeValueHistoryDataDto() {
    return RecoveryCodeValueHistoryDataDto(
      id: id,
      originalCodeId: originalCodeId,
      code: code,
      used: used,
      usedAt: usedAt,
      position: position,
    );
  }
}
