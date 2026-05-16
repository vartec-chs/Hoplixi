import '../db_constraint_descriptor.dart';
import '../../tables/otp/otp_items.dart';

final Map<String, DbConstraintDescriptor> otpRegistry = {
  OtpItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_otp_items_item_id_not_blank',
    entity: 'otp',
    table: 'otp_items',
    field: 'itemId',
    code: 'otp.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  OtpItemConstraint.secretNotEmpty.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_otp_items_secret_not_empty',
    entity: 'otp',
    table: 'otp_items',
    field: 'secret',
    code: 'otp.secret.empty',
    message: 'Секретный ключ (seed) не может быть пустым',
  ),
  OtpItemConstraint.digitsValid.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_otp_items_digits_valid',
    entity: 'otp',
    table: 'otp_items',
    field: 'digits',
    code: 'otp.digits.invalid',
    message: 'Количество цифр должно быть от 6 до 10',
  ),
  OtpItemConstraint.periodPositive.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_otp_items_period_positive',
    entity: 'otp',
    table: 'otp_items',
    field: 'period',
    code: 'otp.period.not_positive',
    message: 'Период обновления должен быть положительным числом',
  ),
};
