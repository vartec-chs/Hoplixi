import 'package:hoplixi/main_db/core/models/dto/bank_card_dto.dart';

import '../../main_store.dart';

extension BankCardItemsDataMapper on BankCardItemsData {
  BankCardDataDto toBankCardDataDto() {
    return BankCardDataDto(
      cardholderName: cardholderName,
      cardNumber: cardNumber,
      cardType: cardType,
      cardTypeOther: cardTypeOther,
      cardNetwork: cardNetwork,
      cardNetworkOther: cardNetworkOther,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: cvv,
      bankName: bankName,
      accountNumber: accountNumber,
      routingNumber: routingNumber,
    );
  }

  BankCardCardDataDto toBankCardCardDataDto() {
    return BankCardCardDataDto(
      cardholderName: cardholderName,
      cardType: cardType,
      cardNetwork: cardNetwork,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      bankName: bankName,
      hasCvv: cvv?.isNotEmpty ?? false,
      hasCardNumber: cardNumber.isNotEmpty,
    );
  }
}
