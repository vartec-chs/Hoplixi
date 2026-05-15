import 'package:hoplixi/main_db/core/main_store.dart';
import 'package:hoplixi/main_db/core/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/main_db/core/models/dto/loyalty_card_history_dto.dart';

extension LoyaltyCardItemsDataMapper on LoyaltyCardItemsData {
  LoyaltyCardDataDto toLoyaltyCardDataDto() {
    return LoyaltyCardDataDto(
      programName: programName,
      cardNumber: cardNumber,
      barcodeValue: barcodeValue,
      password: password,
      barcodeType: barcodeType,
      barcodeTypeOther: barcodeTypeOther,
      issuer: issuer,
      website: website,
      phone: phone,
      email: email,
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  LoyaltyCardCardDataDto toLoyaltyCardCardDataDto() {
    return LoyaltyCardCardDataDto(
      programName: programName,
      barcodeType: barcodeType,
      barcodeTypeOther: barcodeTypeOther,
      issuer: issuer,
      website: website,
      phone: phone,
      email: email,
      validFrom: validFrom,
      validTo: validTo,
      hasCardNumber: cardNumber != null && cardNumber!.isNotEmpty,
      hasBarcodeValue: barcodeValue != null && barcodeValue!.isNotEmpty,
      hasPassword: password != null && password!.isNotEmpty,
    );
  }
}

extension LoyaltyCardHistoryDataMapper on LoyaltyCardHistoryData {
  LoyaltyCardHistoryDataDto toLoyaltyCardHistoryDataDto() {
    return LoyaltyCardHistoryDataDto(
      programName: programName,
      cardNumber: cardNumber,
      barcodeValue: barcodeValue,
      password: password,
      barcodeType: barcodeType,
      barcodeTypeOther: barcodeTypeOther,
      issuer: issuer,
      website: website,
      phone: phone,
      email: email,
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  LoyaltyCardHistoryCardDataDto toLoyaltyCardHistoryCardDataDto() {
    return LoyaltyCardHistoryCardDataDto(
      programName: programName,
      barcodeType: barcodeType,
      barcodeTypeOther: barcodeTypeOther,
      issuer: issuer,
      website: website,
      phone: phone,
      email: email,
      validFrom: validFrom,
      validTo: validTo,
      hasCardNumber: cardNumber != null && cardNumber!.isNotEmpty,
      hasBarcodeValue: barcodeValue != null && barcodeValue!.isNotEmpty,
      hasPassword: password != null && password!.isNotEmpty,
    );
  }
}
