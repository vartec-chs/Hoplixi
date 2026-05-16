import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/main_db/core/errors/db_error.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/validators/api_key_validator.dart';

void main() {
  group('ApiKeyValidator', () {
    test('create with blank service returns validation error', () {
      final dto = const CreateApiKeyDto(
        item: VaultItemCreateDto(name: 'Test'),
        apiKey: ApiKeyDataDto(service: '   ', key: 'secret-key'),
      );

      final error = validateCreateApiKey(dto);

      expect(error, isNotNull);
      expect(error, isA<DbValidationError>());
      final validationError = error as DbValidationError;
      expect(validationError.field, 'service');
      expect(validationError.code, 'api_key.service.not_blank');
    });

    test('create with blank key returns validation error', () {
      final dto = const CreateApiKeyDto(
        item: VaultItemCreateDto(name: 'Test'),
        apiKey: ApiKeyDataDto(service: 'MyService', key: '   '),
      );

      final error = validateCreateApiKey(dto);

      expect(error, isNotNull);
      expect(error, isA<DbValidationError>());
      final validationError = error as DbValidationError;
      expect(validationError.field, 'key');
      expect(validationError.code, 'api_key.key.not_blank');
    });
  });
}
