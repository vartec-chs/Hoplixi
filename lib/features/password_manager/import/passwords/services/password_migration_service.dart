import 'package:hoplixi/main_db/core/dao/index.dart';
import 'package:hoplixi/main_db/core/models/dto/password_dto.dart';
import 'package:result_dart/result_dart.dart';

class PasswordMigrationService {
  final PasswordDao _passwordDao;

  PasswordMigrationService(this._passwordDao);

  Future<Result<int>> savePasswords(List<CreatePasswordDto> passwords) async {
    try {
      for (final dto in passwords) {
        await _passwordDao.createPassword(dto);
      }

      return Success(passwords.length);
    } catch (error) {
      return Failure(Exception('Не удалось сохранить пароли: $error'));
    }
  }
}
