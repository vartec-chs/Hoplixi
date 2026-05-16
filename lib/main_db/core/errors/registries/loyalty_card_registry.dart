import '../db_constraint_descriptor.dart';
import '../../tables/loyalty_card/loyalty_card_items.dart';

final Map<String, DbConstraintDescriptor> loyaltyCardRegistry = {
  LoyaltyCardItemConstraint.itemIdNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_loyalty_card_items_item_id_not_blank',
    entity: 'loyaltyCard',
    table: 'loyalty_card_items',
    field: 'itemId',
    code: 'loyalty_card.item_id.not_blank',
    message: 'ID записи не может быть пустым',
  ),
  LoyaltyCardItemConstraint.programNameNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_loyalty_card_items_program_name_not_blank',
    entity: 'loyaltyCard',
    table: 'loyalty_card_items',
    field: 'programName',
    code: 'loyalty_card.program_name.not_blank',
    message: 'Название программы не может быть пустым',
  ),
  LoyaltyCardItemConstraint.cardNumberNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_loyalty_card_items_card_number_not_blank',
    entity: 'loyaltyCard',
    table: 'loyalty_card_items',
    field: 'cardNumber',
    code: 'loyalty_card.card_number.not_blank',
    message: 'Номер карты не может быть пустым',
  ),
  LoyaltyCardItemConstraint.barcodeValueNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_loyalty_card_items_barcode_value_not_blank',
    entity: 'loyaltyCard',
    table: 'loyalty_card_items',
    field: 'barcodeValue',
    code: 'loyalty_card.barcode_value.not_blank',
    message: 'Значение штрихкода не может быть пустым',
  ),
  LoyaltyCardItemConstraint.validDateRange.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_loyalty_card_items_valid_date_range',
    entity: 'loyaltyCard',
    table: 'loyalty_card_items',
    field: 'validTo',
    code: 'loyalty_card.valid_range.invalid',
    message: 'Дата окончания действия должна быть позже даты начала',
  ),
};
