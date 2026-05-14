import 'package:hoplixi/main_db/core/models/dto/license_key_dto.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

extension LicenseKeyItemsDataMapper on LicenseKeyItemsData {
  LicenseKeyDataDto toLicenseKeyDataDto() {
    return LicenseKeyDataDto(
      productName: productName,
      vendor: vendor,
      licenseKey: licenseKey,
      licenseType: licenseType,
      licenseTypeOther: licenseTypeOther,
      accountEmail: accountEmail,
      accountUsername: accountUsername,
      purchaseEmail: purchaseEmail,
      orderNumber: orderNumber,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      currency: currency,
      validFrom: validFrom,
      validTo: validTo,
      renewalDate: renewalDate,
      seats: seats,
      activationLimit: activationLimit,
      activationsUsed: activationsUsed,
    );
  }

  LicenseKeyCardDataDto toLicenseKeyCardDataDto() {
    return LicenseKeyCardDataDto(
      productName: productName,
      vendor: vendor,
      licenseType: licenseType,
      accountEmail: accountEmail,
      accountUsername: accountUsername,
      validTo: validTo,
      hasKey: licenseKey.isNotEmpty,
    );
  }
}
