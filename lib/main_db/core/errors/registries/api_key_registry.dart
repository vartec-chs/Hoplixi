import '../db_constraint_descriptor.dart';
import '../../tables/api_key/api_key_items.dart';

final Map<String, DbConstraintDescriptor> apiKeyRegistry = {
  ApiKeyItemConstraint.serviceNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_service_not_blank',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'service',
        code: 'api_key.service.not_blank',
        message: 'Название сервиса не может быть пустым',
      ),
  ApiKeyItemConstraint.serviceNoOuterWhitespace.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_service_no_outer_whitespace',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'service',
        code: 'api_key.service.no_outer_whitespace',
        message:
            'Название сервиса не должно начинаться или заканчиваться пробелами',
      ),
  ApiKeyItemConstraint.keyNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_api_key_items_key_not_blank',
    entity: 'apiKey',
    table: 'api_key_items',
    field: 'key',
    code: 'api_key.key.not_blank',
    message: 'API ключ не может быть пустым',
  ),
  ApiKeyItemConstraint.tokenTypeOtherRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_token_type_other_required',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'tokenTypeOther',
        code: 'api_key.token_type_other.required',
        message: 'Укажите свой тип токена',
      ),
  ApiKeyItemConstraint.tokenTypeOtherMustBeNull.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_token_type_other_must_be_null',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'tokenTypeOther',
        code: 'api_key.token_type_other.must_be_null',
        message: 'Свой тип токена можно указывать только для значения other',
      ),
  ApiKeyItemConstraint.environmentOtherRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_environment_other_required',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'environmentOther',
        code: 'api_key.environment_other.required',
        message: 'Укажите своё окружение',
      ),
  ApiKeyItemConstraint.environmentOtherMustBeNull.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_environment_other_must_be_null',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'environmentOther',
        code: 'api_key.environment_other.must_be_null',
        message: 'Своё окружение можно указывать только для значения other',
      ),
  ApiKeyItemConstraint.revokedAtStateConsistent.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_revoked_at_state_consistent',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'revokedAt',
        code: 'api_key.revoked_at.state_consistent',
        message: 'Дата отзыва ключа указана некорректно',
      ),
  ApiKeyItemConstraint.rotationPeriodPositive.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_rotation_period_positive',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'rotationPeriodDays',
        code: 'api_key.rotation_period.positive',
        message: 'Период ротации должен быть положительным числом',
      ),
  ApiKeyItemConstraint.lastRotatedRequiresRotationPeriod.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_api_key_items_last_rotated_requires_rotation_period',
        entity: 'apiKey',
        table: 'api_key_items',
        field: 'lastRotatedAt',
        code: 'api_key.last_rotated.requires_rotation_period',
        message: 'Дата последней ротации требует указания периода ротации',
      ),
};
