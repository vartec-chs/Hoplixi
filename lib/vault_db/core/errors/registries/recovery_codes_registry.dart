import '../db_constraint_descriptor.dart';
import '../../scheme/tables/recovery_codes/recovery_codes_items.dart';

final Map<String, DbConstraintDescriptor> recoveryCodesRegistry = {
  RecoveryCodesItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_recovery_codes_items_item_id_not_blank',
        entity: 'recoveryCodes',
        table: 'recovery_codes_items',
        field: 'itemId',
        code: 'recovery_codes.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),

};
