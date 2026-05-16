import '../db_constraint_descriptor.dart';
import '../../tables/contact/contact_items.dart';

final Map<String, DbConstraintDescriptor> contactRegistry = {
  ContactItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_contact_items_item_id_not_blank',
    entity: 'contact',
    table: 'contact_items',
    field: 'itemId',
    code: 'contact.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  ContactItemConstraint.firstNameNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_contact_items_first_name_not_blank',
    entity: 'contact',
    table: 'contact_items',
    field: 'firstName',
    code: 'contact.first_name.not_blank',
    message: 'Имя не может состоять из одних пробелов',
  ),
  ContactItemConstraint.lastNameNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_contact_items_last_name_not_blank',
    entity: 'contact',
    table: 'contact_items',
    field: 'lastName',
    code: 'contact.last_name.not_blank',
    message: 'Фамилия не может состоять из одних пробелов',
  ),
};
