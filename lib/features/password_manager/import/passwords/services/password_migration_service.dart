import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/services/entities/password_service.dart';
import 'package:result_dart/result_dart.dart';

class PasswordMigrationService {
  final PasswordService _passwordService;

  PasswordMigrationService(this._passwordService);

  Future<Result<int>> savePasswords(List<CreatePasswordDto> passwords) async {
    try {
      for (final dto in passwords) {
        await _passwordService.create(dto);
      }

      return Success(passwords.length);
    } catch (error) {
      return Failure(Exception('Не удалось сохранить пароли: $error'));
    }
  }
}
