import 'package:drift/drift.dart';

import 'documents.dart';
import 'tags.dart';

@DataClassName('DocumentsTagsData')
class DocumentsTags extends Table {
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {documentId, tagId};

  @override
  String get tableName => 'documents_tags';
}
