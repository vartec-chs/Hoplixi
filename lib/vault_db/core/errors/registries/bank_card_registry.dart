import '../db_constraint_descriptor.dart';
import '../../tables/bank_card/bank_card_items.dart';

final Map<String, DbConstraintDescriptor> bankCardRegistry = {
  BankCardItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_item_id_not_blank',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'itemId',
        code: 'bank_card.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
  BankCardItemConstraint.cardholderNameNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_cardholder_name_not_blank',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'cardholderName',
        code: 'bank_card.cardholder_name.not_blank',
        message: 'Имя владельца не может состоять из одних пробелов',
      ),
  BankCardItemConstraint.cardNumberNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_card_number_not_blank',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'cardNumber',
        code: 'bank_card.card_number.not_blank',
        message: 'Номер карты не может быть пустым',
      ),
  BankCardItemConstraint.cardTypeOtherRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_card_type_other_required',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'cardTypeOther',
        code: 'bank_card.card_type_other.required',
        message: 'Укажите свой тип карты',
      ),
  BankCardItemConstraint.cardNetworkOtherRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_card_network_other_required',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'cardNetworkOther',
        code: 'bank_card.card_network_other.required',
        message: 'Укажите свою платежную систему',
      ),
  BankCardItemConstraint.expiryMonthValid.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_expiry_month_valid',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'expiryMonth',
        code: 'bank_card.expiry_month.invalid',
        message: 'Некорректный месяц истечения срока действия',
      ),
  BankCardItemConstraint.expiryYearValid.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_expiry_year_valid',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'expiryYear',
        code: 'bank_card.expiry_year.invalid',
        message: 'Некорректный год истечения срока действия',
      ),
  BankCardItemConstraint.cvvNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_bank_card_items_cvv_not_blank',
        entity: 'bankCard',
        table: 'bank_card_items',
        field: 'cvv',
        code: 'bank_card.cvv.not_blank',
        message: 'CVV код не может быть пустым',
      ),
};
