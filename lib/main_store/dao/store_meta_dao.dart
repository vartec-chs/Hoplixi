import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/tables/store_meta_table.dart';
import 'package:uuid/uuid.dart';

part 'store_meta_dao.g.dart';

@DriftAccessor(tables: [StoreMetaTable])
class StoreMetaDao extends DatabaseAccessor<MainStore>
    with _$StoreMetaDaoMixin {
  StoreMetaDao(super.db);

  /// Получить мета-информацию о хранилище (всегда первая запись)
  Future<StoreMeta?> getStoreMeta() async {
    final query = select(storeMetaTable)..limit(1);
    return await query.getSingleOrNull();
  }

  /// Создать первую запись мета-информации
  Future<String> createStoreMeta({
    required String name,
    required String passwordHash,
    required String salt,
    required String attachmentKey,
    String? description,
    String version = '1.0.0',
  }) async {
    final uuid = const Uuid().v4();
    final companion = StoreMetaTableCompanion.insert(
      id: Value(uuid),
      name: name,
      passwordHash: passwordHash,
      salt: salt,
      attachmentKey: attachmentKey,
      description: Value(description),
      version: Value(version),
    );

    await into(storeMetaTable).insert(companion);
    return uuid;
  }

  /// Обновить имя хранилища
  Future<bool> updateName(String newName) async {
    final meta = await getStoreMeta();
    if (meta == null) return false;

    final result =
        await (update(
          storeMetaTable,
        )..where((t) => t.id.equals(meta.id))).write(
          StoreMetaTableCompanion(
            name: Value(newName),
            modifiedAt: Value(DateTime.now()),
          ),
        );

    return result > 0;
  }

  /// Обновить описание хранилища
  Future<bool> updateDescription(String? newDescription) async {
    final meta = await getStoreMeta();
    if (meta == null) return false;

    final result =
        await (update(
          storeMetaTable,
        )..where((t) => t.id.equals(meta.id))).write(
          StoreMetaTableCompanion(
            description: Value(newDescription),
            modifiedAt: Value(DateTime.now()),
          ),
        );

    return result > 0;
  }

  /// Обновить время последнего открытия
  Future<bool> updateLastOpenedAt() async {
    final meta = await getStoreMeta();
    if (meta == null) return false;

    final result =
        await (update(
          storeMetaTable,
        )..where((t) => t.id.equals(meta.id))).write(
          StoreMetaTableCompanion(lastOpenedAt: Value(DateTime.now())),
        );

    return result > 0;
  }

  /// Обновить хеш пароля и соль
  Future<bool> updatePasswordHash({
    required String newPasswordHash,
    required String newSalt,
  }) async {
    final meta = await getStoreMeta();
    if (meta == null) return false;

    final result =
        await (update(
          storeMetaTable,
        )..where((t) => t.id.equals(meta.id))).write(
          StoreMetaTableCompanion(
            passwordHash: Value(newPasswordHash),
            salt: Value(newSalt),
            modifiedAt: Value(DateTime.now()),
          ),
        );

    return result > 0;
  }

  /// Изменить пароль базы данных (SQLCipher PRAGMA rekey)
  /// не работает
  Future<void> changePassword(String newPassword) async {
    // PRAGMA не поддерживает параметры, нужна прямая подстановка
    // Экранируем одинарные кавычки в пароле
    final escapedPassword = newPassword.replaceAll("'", "''");
    await db.customStatement("PRAGMA cipher_page_size = 4096;");
    await db.customStatement("PRAGMA kdf_iter = 256000;");
    await db.customStatement("PRAGMA cipher_hmac_algorithm = HMAC_SHA512;");
    await db.customStatement(
      "PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;",
    );
    await db.customStatement("PRAGMA key = '$escapedPassword';");
  }

  /// Обновить ключ для вложений
  Future<bool> updateAttachmentKey(String newAttachmentKey) async {
    final meta = await getStoreMeta();
    if (meta == null) return false;

    final result =
        await (update(
          storeMetaTable,
        )..where((t) => t.id.equals(meta.id))).write(
          StoreMetaTableCompanion(
            attachmentKey: Value(newAttachmentKey),
            modifiedAt: Value(DateTime.now()),
          ),
        );

    return result > 0;
  }

  /// Обновить версию схемы
  Future<bool> updateVersion(String newVersion) async {
    final meta = await getStoreMeta();
    if (meta == null) return false;

    final result =
        await (update(
          storeMetaTable,
        )..where((t) => t.id.equals(meta.id))).write(
          StoreMetaTableCompanion(
            version: Value(newVersion),
            modifiedAt: Value(DateTime.now()),
          ),
        );

    return result > 0;
  }

  /// Следить за изменениями мета-информации
  Stream<StoreMeta?> watchStoreMeta() {
    return (select(storeMetaTable)..limit(1)).watchSingleOrNull();
  }
}
