import '../db_constraint_descriptor.dart';
import '../../tables/ssh_key/ssh_key_items.dart';

final Map<String, DbConstraintDescriptor> sshKeyRegistry = {
  SshKeyItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_ssh_key_items_item_id_not_blank',
    entity: 'sshKey',
    table: 'ssh_key_items',
    field: 'itemId',
    code: 'ssh_key.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  SshKeyItemConstraint.authMaterialRequired.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_ssh_key_items_auth_material_required',
    entity: 'sshKey',
    table: 'ssh_key_items',
    field: 'privateKey',
    code: 'ssh_key.material.required',
    message: 'Необходимо указать публичный или приватный ключ',
  ),
  SshKeyItemConstraint.keySizePositive.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_ssh_key_items_key_size_positive',
    entity: 'sshKey',
    table: 'ssh_key_items',
    field: 'keySize',
    code: 'ssh_key.key_size.not_positive',
    message: 'Размер ключа должен быть положительным числом',
  ),
};
