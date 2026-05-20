import '../db_constraint_descriptor.dart';
import '../../tables/document/document_items.dart';

final Map<String, DbConstraintDescriptor> documentRegistry = {
  DocumentItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_document_items_item_id_not_blank',
        entity: 'document',
        table: 'document_items',
        field: 'itemId',
        code: 'document.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
};
