import 'package:hoplixi/main_db/core/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

extension LoyaltyCardItemsDataMapper on LoyaltyCardItemsData {
  LoyaltyCardDataDto toLoyaltyCardDataDto() {
    return LoyaltyCardDataDto(
      programName: programName,
      cardNumber: cardNumber,
      memberSince: memberSince,
      expiryDate: expiryDate,
      points: points,
      tier: tier,
      notes: notes,
    );
  }

  LoyaltyCardCardDataDto toLoyaltyCardCardDataDto() {
    return LoyaltyCardCardDataDto(
      programName: programName,
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      points: points,
      tier: tier,
    );
  }
}

