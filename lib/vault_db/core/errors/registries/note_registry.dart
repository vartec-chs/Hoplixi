import '../db_constraint_descriptor.dart';
import '../../tables/note/note_items.dart';

final Map<String, DbConstraintDescriptor> noteRegistry = {
  NoteItemConstraint.itemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_note_items_item_id_not_blank',
        entity: 'note',
        table: 'note_items',
        field: 'itemId',
        code: 'note.item_id.not_blank',
        message: 'ID записи не может быть пустым',
      ),
  NoteItemConstraint.contentNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_note_items_content_not_blank',
        entity: 'note',
        table: 'note_items',
        field: 'content',
        code: 'note.content.not_blank',
        message: 'Содержимое заметки не может состоять из одних пробелов',
      ),
};
