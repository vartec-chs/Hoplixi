import '../db_constraint_descriptor.dart';
import '../../tables/password/password_items.dart';

final Map<String, DbConstraintDescriptor> passwordRegistry = {
  PasswordItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_item_id_not_blank',
    entity: 'password',
    table: 'password_items',
    field: 'itemId',
    code: 'password.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  PasswordItemConstraint.loginNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_login_not_blank',
    entity: 'password',
    table: 'password_items',
    field: 'login',
    code: 'password.login.not_blank',
    message: 'Логин не может состоять из одних пробелов',
  ),
  PasswordItemConstraint.loginNoOuterWhitespace.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_login_no_outer_whitespace',
    entity: 'password',
    table: 'password_items',
    field: 'login',
    code: 'password.login.no_outer_whitespace',
    message: 'Логин не должен начинаться или заканчиваться пробелами',
  ),
  PasswordItemConstraint.emailNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_email_not_blank',
    entity: 'password',
    table: 'password_items',
    field: 'email',
    code: 'password.email.not_blank',
    message: 'Email не может состоять из одних пробелов',
  ),
  PasswordItemConstraint.emailNoOuterWhitespace.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_email_no_outer_whitespace',
    entity: 'password',
    table: 'password_items',
    field: 'email',
    code: 'password.email.no_outer_whitespace',
    message: 'Email не должен начинаться или заканчиваться пробелами',
  ),
  PasswordItemConstraint.passwordNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_password_not_blank',
    entity: 'password',
    table: 'password_items',
    field: 'password',
    code: 'password.password.not_blank',
    message: 'Пароль не может быть пустым',
  ),
  PasswordItemConstraint.urlNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_url_not_blank',
    entity: 'password',
    table: 'password_items',
    field: 'url',
    code: 'password.url.not_blank',
    message: 'URL не может состоять из одних пробелов',
  ),
  PasswordItemConstraint.urlNoOuterWhitespace.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_password_items_url_no_outer_whitespace',
    entity: 'password',
    table: 'password_items',
    field: 'url',
    code: 'password.url.no_outer_whitespace',
    message: 'URL не должен начинаться или заканчиваться пробелами',
  ),
};
