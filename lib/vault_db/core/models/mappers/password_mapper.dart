import 'package:hoplixi/vault_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension PasswordItemsDataMapper on PasswordItemsData {
  PasswordDataDto toPasswordDataDto() {
    return PasswordDataDto(
      login: login,
      email: email,
      password: password,
      url: url,
      expiresAt: expiresAt,
    );
  }

  PasswordCardDataDto toPasswordCardDataDto() {
    return PasswordCardDataDto(
      login: login,
      email: email,
      url: url,
      expiresAt: expiresAt,
      hasPassword: password.isNotEmpty,
    );
  }
}
