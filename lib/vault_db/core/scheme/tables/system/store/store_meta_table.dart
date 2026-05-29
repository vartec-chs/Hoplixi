import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Singleton table for current store metadata.
///
/// В таблице всегда должна быть ровно одна строка.
/// Поле [id] — это глобальный UUID хранилища, который используется
/// для привязки manifest, encrypted attachments, sync metadata и т.д.
@DataClassName('StoreMetaData')
class StoreMetaTable extends Table {
  /// Singleton marker. Always 1.
  IntColumn get singletonId => integer().withDefault(const Constant(1))();

  /// Глобальный UUID хранилища.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// Название хранилища.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Описание хранилища.
  TextColumn get description => text().nullable()();

  /// Хэш/верификатор мастер-пароля.
  TextColumn get passwordHash => text()();

  /// Соль для хэширования пароля.
  TextColumn get passwordSalt => text()();

  /// Ключ для attachments.
  TextColumn get attachmentKey => text()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get lastOpenedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {singletonId};

  @override
  String get tableName => 'store_meta';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${StoreMetaConstraint.singletonId.constraintName}
    CHECK (
      singleton_id = 1
    )
    ''',

    '''
    CONSTRAINT ${StoreMetaConstraint.idNotBlank.constraintName}
    CHECK (
      length(trim(id)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreMetaConstraint.nameNotBlank.constraintName}
    CHECK (
      length(trim(name)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreMetaConstraint.descriptionNotBlank.constraintName}
    CHECK (
      description IS NULL
      OR length(trim(description)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreMetaConstraint.passwordHashNotBlank.constraintName}
    CHECK (
      length(trim(password_hash)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreMetaConstraint.passwordSaltNotBlank.constraintName}
    CHECK (
      length(trim(password_salt)) > 0
    )
    ''',

    '''
    CONSTRAINT ${StoreMetaConstraint.attachmentKeyNotBlank.constraintName}
    CHECK (
      length(trim(attachment_key)) > 0
    )
    ''',
  ];
}

enum StoreMetaConstraint {
  singletonId('chk_store_meta_singleton_id'),

  idNotBlank('chk_store_meta_id_not_blank'),

  nameNotBlank('chk_store_meta_name_not_blank'),

  descriptionNotBlank('chk_store_meta_description_not_blank'),

  passwordHashNotBlank('chk_store_meta_password_hash_not_blank'),

  passwordSaltNotBlank('chk_store_meta_password_salt_not_blank'),

  attachmentKeyNotBlank('chk_store_meta_attachment_key_not_blank');

  const StoreMetaConstraint(this.constraintName);

  final String constraintName;
}

enum StoreMetaTrigger {
  preventMultipleRowsOnInsert('trg_store_meta_prevent_multiple_rows_on_insert'),

  preventSingletonIdUpdate('trg_store_meta_prevent_singleton_id_update');

  const StoreMetaTrigger(this.triggerName);

  final String triggerName;
}

enum StoreMetaRaise {
  onlyOneRowAllowed('store_meta can contain only one row'),

  singletonIdImmutable('store_meta.singleton_id is immutable');

  const StoreMetaRaise(this.message);

  final String message;
}

final List<String> storeMetaTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${StoreMetaTrigger.preventMultipleRowsOnInsert.triggerName}
  BEFORE INSERT ON store_meta
  FOR EACH ROW
  WHEN EXISTS (
    SELECT 1
    FROM store_meta
  )
  BEGIN
    SELECT RAISE(
      ABORT,
      '${StoreMetaRaise.onlyOneRowAllowed.message}'
    );
  END;
  ''',

  '''
  CREATE TRIGGER IF NOT EXISTS ${StoreMetaTrigger.preventSingletonIdUpdate.triggerName}
  BEFORE UPDATE OF singleton_id ON store_meta
  FOR EACH ROW
  WHEN NEW.singleton_id <> OLD.singleton_id
  BEGIN
    SELECT RAISE(
      ABORT,
      '${StoreMetaRaise.singletonIdImmutable.message}'
    );
  END;
  ''',
];
