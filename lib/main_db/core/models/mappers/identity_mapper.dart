import 'package:hoplixi/main_db/core/models/dto/identity_dto.dart';
import '../../main_store.dart';

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
