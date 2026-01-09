import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/main_store/dao/password_dao.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:result_dart/result_dart.dart';

class PasswordMigrationService {
  final PasswordDao _passwordDao;

  PasswordMigrationService(this._passwordDao);

  /// Generates a JSON file with [count] empty password templates at [path].
  Future<Result<String>> generateTemplate(int count, String path) async {
    try {
      final file = File(path);
      final templates = List.generate(
        count,
        (index) => {
          'name': '',
          'password': '',
          'login': '',
          'email': '',
          'url': '',
          'description': '',
        },
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(templates);
      await file.writeAsString(jsonString);
      return Success(path);
    } catch (e) {
      return Failure(Exception('Failed to generate template: $e'));
    }
  }

  /// Parses passwords from a JSON file at [path] without saving them.
  Future<Result<List<CreatePasswordDto>>> parseImportFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return Failure(Exception('File not found: $path'));
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<CreatePasswordDto> passwords = [];
      int errorIndex = -1;

      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          final name = item['name'] as String? ?? '';
          final password = item['password'] as String? ?? '';
          final login = item['login'] as String?;
          final email = item['email'] as String?;
          errorIndex += 1;

          // Validation: name and password are required
          if (name.trim().isEmpty || password.trim().isEmpty) {
            return Failure(
              Exception(
                'Отсутствуют обязательные поля. У ${errorIndex + 1}-го пароля отсутствует имя или пароль.',
              ),
            );
          }

          // Validation: at least one of login or email must be present
          if ((login == null || login.trim().isEmpty) &&
              (email == null || email.trim().isEmpty)) {
            return Failure(
              Exception(
                'Отсутствуют обязательные поля. У пароля "$name" нет ни логина, ни email.',
              ),
            );
          }

          final dto = CreatePasswordDto(
            name: name.trim(),
            password: password.trim(),
            login: login?.trim().isNotEmpty == true ? login!.trim() : null,
            email: email?.trim().isNotEmpty == true ? email!.trim() : null,
            url: item['url'] as String?,
            description: item['description'] as String?,
          );
          passwords.add(dto);
        }
      }
      return Success(passwords);
    } catch (e) {
      return Failure(Exception('Failed to parse passwords: $e'));
    }
  }

  /// Saves a list of passwords to the database.
  Future<Result<bool>> savePasswords(List<CreatePasswordDto> passwords) async {
    try {
      for (final dto in passwords) {
        await _passwordDao.createPassword(dto);
      }
      return const Success(true);
    } catch (e) {
      return Failure(Exception('Failed to save passwords: $e'));
    }
  }

  /// Deletes the import file.
  Future<Result<bool>> deleteImportFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return const Success(true);
      }
      return Failure(Exception('File not found'));
    } catch (e) {
      return Failure(Exception('Failed to delete file: $e'));
    }
  }
}
