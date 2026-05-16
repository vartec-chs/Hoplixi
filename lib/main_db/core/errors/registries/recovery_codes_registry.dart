import '../db_constraint_descriptor.dart';
import '../../tables/recovery_codes/recovery_codes_items.dart';

final Map<String, DbConstraintDescriptor> recoveryCodesRegistry = {
  RecoveryCodesItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_recovery_codes_items_item_id_not_blank',
    entity: 'recoveryCodes',
    table: 'recovery_codes_items',
    field: 'itemId',
    code: 'recovery_codes.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  RecoveryCodesItemConstraint.codesCountNonNegative.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_recovery_codes_items_codes_count_non_negative',
    entity: 'recoveryCodes',
    table: 'recovery_codes_items',
    field: 'codesCount',
    code: 'recovery_codes.count.negative',
    message: 'Количество кодов не может быть отрицательным',
  ),
  RecoveryCodesItemConstraint.usedCountNotGreaterThanCodesCount.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_recovery_codes_items_used_count_not_greater_than_codes_count',
    entity: 'recoveryCodes',
    table: 'recovery_codes_items',
    field: 'usedCount',
    code: 'recovery_codes.used_count.overflow',
    message: 'Использовано больше кодов, чем существует',
  ),
};
