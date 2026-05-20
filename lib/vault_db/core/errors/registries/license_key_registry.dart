import '../db_constraint_descriptor.dart';
import '../../tables/license_key/license_key_items.dart';

final Map<String, DbConstraintDescriptor> licenseKeyRegistry = {
  LicenseKeyItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_license_key_items_item_id_not_blank',
        entity: 'licenseKey',
        table: 'license_key_items',
        field: 'itemId',
        code: 'license_key.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
  LicenseKeyItemConstraint.licenseKeyNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_license_key_items_license_key_not_blank',
        entity: 'licenseKey',
        table: 'license_key_items',
        field: 'licenseKey',
        code: 'license_key.key.not_blank',
        message: 'Лицензионный ключ не может быть пустым',
      ),
  LicenseKeyItemConstraint.productNameNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_license_key_items_product_name_not_blank',
        entity: 'licenseKey',
        table: 'license_key_items',
        field: 'productName',
        code: 'license_key.product_name.not_blank',
        message: 'Название продукта не может быть пустым',
      ),
  LicenseKeyItemConstraint.accountEmailNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_license_key_items_account_email_not_blank',
        entity: 'licenseKey',
        table: 'license_key_items',
        field: 'accountEmail',
        code: 'license_key.account_email.not_blank',
        message: 'Email аккаунта не может состоять из одних пробелов',
      ),
  LicenseKeyItemConstraint.licenseTypeOtherRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_license_key_items_license_type_other_required',
        entity: 'licenseKey',
        table: 'license_key_items',
        field: 'licenseTypeOther',
        code: 'license_key.type_other.required',
        message: 'Укажите свой тип лицензии',
      ),
};
