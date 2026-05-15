import 'package:hoplixi/main_db/core/models/dto/contact_dto.dart';

import '../../main_store.dart';

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
