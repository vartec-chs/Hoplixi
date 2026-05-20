import '../db_constraint_descriptor.dart';
import '../../tables/identity/identity_items.dart';

final Map<String, DbConstraintDescriptor> identityRegistry = {
  IdentityItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_identity_items_item_id_not_blank',
        entity: 'identity',
        table: 'identity_items',
        field: 'itemId',
        code: 'identity.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
  IdentityItemConstraint.atLeastOneIdentifyingField.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_identity_items_at_least_one_identifying_field',
        entity: 'identity',
        table: 'identity_items',
        field: 'displayName',
        code: 'identity.identifying_field.required',
        message: 'Укажите хотя бы одно поле (имя, логин, email или компания)',
      ),
};
// Note: Many other constraints are whitespace-only, which are less critical for detailed user feedback but still mapable.
