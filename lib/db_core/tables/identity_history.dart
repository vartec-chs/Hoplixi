import 'package:drift/drift.dart';

import 'vault_item_history.dart';
import 'vault_items.dart';

@DataClassName('IdentityHistoryData')
class IdentityHistory extends Table {
  @ReferenceName('identityHistoryEntry')
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  TextColumn get idType => text()();

  TextColumn get idNumber => text()();

  TextColumn get fullName => text().nullable()();

  DateTimeColumn get dateOfBirth => dateTime().nullable()();

  TextColumn get placeOfBirth => text().nullable()();

  TextColumn get nationality => text().nullable()();

  TextColumn get issuingAuthority => text().nullable()();

  DateTimeColumn get issueDate => dateTime().nullable()();

  DateTimeColumn get expiryDate => dateTime().nullable()();

  TextColumn get mrz => text().nullable()();

  /// Ссылка на скан-документ в хранилище (document_items → vault_items)
  @ReferenceName('identityHistoryScanAttachment')
  TextColumn get scanAttachmentId => text()
      .references(VaultItems, #id, onDelete: KeyAction.setNull)
      .nullable()();

  /// Ссылка на фото-файл в хранилище (file_items → vault_items)
  @ReferenceName('identityHistoryPhotoAttachment')
  TextColumn get photoAttachmentId => text()
      .references(VaultItems, #id, onDelete: KeyAction.setNull)
      .nullable()();

  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'identity_history';
}
