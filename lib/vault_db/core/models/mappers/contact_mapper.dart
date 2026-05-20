import 'package:hoplixi/vault_db/core/models/dto/contact_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension ContactItemsDataMapper on ContactItemsData {
  ContactDataDto toContactDataDto() {
    return ContactDataDto(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      company: company,
      jobTitle: jobTitle,
      email: email,
      phone: phone,
      address: address,
      website: website,
      birthday: birthday,
    );
  }

  ContactCardDataDto toContactCardDataDto() {
    return ContactCardDataDto(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      company: company,
      email: email,
      phone: phone,
      isEmergencyContact: isEmergencyContact,
    );
  }
}
