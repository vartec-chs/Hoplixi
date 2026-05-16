import '../db_constraint_descriptor.dart';
import '../../tables/wifi/wifi_items.dart';

final Map<String, DbConstraintDescriptor> wifiRegistry = {
  WifiItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_wifi_items_item_id_not_blank',
    entity: 'wifi',
    table: 'wifi_items',
    field: 'itemId',
    code: 'wifi.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  WifiItemConstraint.ssidNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_wifi_items_ssid_not_blank',
    entity: 'wifi',
    table: 'wifi_items',
    field: 'ssid',
    code: 'wifi.ssid.not_blank',
    message: 'SSID не может быть пустым',
  ),
  WifiItemConstraint.passwordNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_wifi_items_password_not_blank',
    entity: 'wifi',
    table: 'wifi_items',
    field: 'password',
    code: 'wifi.password.not_blank',
    message: 'Пароль Wi-Fi не может состоять из одних пробелов',
  ),
  WifiItemConstraint.passwordSecurityConsistency.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_wifi_items_password_security_consistency',
    entity: 'wifi',
    table: 'wifi_items',
    field: 'password',
    code: 'wifi.password.inconsistent',
    message: 'Несоответствие пароля выбранному типу безопасности',
  ),
};
