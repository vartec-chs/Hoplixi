import 'package:hoplixi/vault_db/core/models/dto/identity_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension IdentityItemsDataMapper on IdentityItemsData {
  IdentityDataDto toIdentityDataDto() {
    return IdentityDataDto(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      displayName: displayName,
      username: username,
      email: email,
      phone: phone,
      address: address,
      birthday: birthday,
      company: company,
      jobTitle: jobTitle,
      website: website,
      taxId: taxId,
      nationalId: nationalId,
      passportNumber: passportNumber,
      driverLicenseNumber: driverLicenseNumber,
    );
  }

  IdentityCardDataDto toIdentityCardDataDto() {
    return IdentityCardDataDto(
      displayName: displayName,
      username: username,
      email: email,
      phone: phone,
      company: company,
    );
  }
}
