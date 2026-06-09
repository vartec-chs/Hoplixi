import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/core/utils/file_name_validator.dart';

void main() {
  group('FileNameValidator', () {
    test('valid names', () {
      expect(FileNameValidator.validate('MyVault'), isNull);
      expect(FileNameValidator.validate('vault-123'), isNull);
      expect(FileNameValidator.validate('vault_backup'), isNull);
      expect(FileNameValidator.validate('Хранилище'), isNull);
      expect(FileNameValidator.isValid('ValidName'), isTrue);
    });

    test('empty or null names', () {
      expect(FileNameValidator.validate(null), 'Название обязательно');
      expect(FileNameValidator.validate(''), 'Название не может быть пустым');
      expect(FileNameValidator.validate('   '), 'Название не может состоять только из пробелов');
    });

    test('reserved names', () {
      expect(FileNameValidator.validate('.'), 'Недопустимое название');
      expect(FileNameValidator.validate('..'), 'Недопустимое название');
    });

    test('forbidden characters', () {
      expect(FileNameValidator.validate('vault/1'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault\\2'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault:3'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault*'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault?'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault"'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault<'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault>'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
      expect(FileNameValidator.validate('vault|'), 'Название содержит запрещённые символы (<>:"/\\|?*)');
    });

    test('internal or trailing space', () {
      expect(FileNameValidator.validate('vault 1'), 'Название не может содержать пробелы');
      expect(FileNameValidator.validate('vault '), 'Название не может содержать пробелы');
      expect(FileNameValidator.validate(' vault'), 'Название не может содержать пробелы');
    });

    test('ending with dot', () {
      expect(FileNameValidator.validate('vault.'), 'Название не может заканчиваться точкой');
    });

    test('Windows reserved names', () {
      expect(FileNameValidator.validate('CON'), 'Это системное зарезервированное имя Windows');
      expect(FileNameValidator.validate('PRN'), 'Это системное зарезервированное имя Windows');
      expect(FileNameValidator.validate('aux'), 'Это системное зарезервированное имя Windows');
      expect(FileNameValidator.validate('Nul'), 'Это системное зарезервированное имя Windows');
      expect(FileNameValidator.validate('COM1'), 'Это системное зарезервированное имя Windows');
      expect(FileNameValidator.validate('LPT9'), 'Это системное зарезервированное имя Windows');
      expect(FileNameValidator.validate('CON.txt'), 'Это системное зарезервированное имя Windows');
    });

    test('max length in bytes', () {
      // 255 bytes limit
      final longName = 'a' * 255;
      expect(FileNameValidator.validate(longName), isNull);
      
      final tooLongName = 'a' * 256;
      expect(FileNameValidator.validate(tooLongName), 'Название слишком длинное');

      // Multi-byte characters (Russian characters are 2 bytes in UTF-8)
      final russianName = 'я' * 127; // 254 bytes
      expect(FileNameValidator.validate(russianName), isNull);

      final tooLongRussianName = 'я' * 128; // 256 bytes
      expect(FileNameValidator.validate(tooLongRussianName), 'Название слишком длинное');
    });
  });
}
