import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/password_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'password_dao.g.dart';

@DriftAccessor(tables: [VaultItems, PasswordItems])
class PasswordDao extends DatabaseAccessor<MainStore> with _$PasswordDaoMixin {
  PasswordDao(super.db);

  /// Получить все пароли (JOIN vault_items + password_items)
  Future<List<(VaultItemsData, PasswordItemsData)>> getAllPasswords() async {
    final query = select(vaultItems).join([
      innerJoin(passwordItems, passwordItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(passwordItems)))
        .toList();
  }

  /// Получить пароль по ID
  Future<(VaultItemsData, PasswordItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(passwordItems, passwordItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(passwordItems));
  }

  /// Смотреть все пароли с автообновлением
  Stream<List<(VaultItemsData, PasswordItemsData)>> watchAllPasswords() {
    final query = select(vaultItems).join([
      innerJoin(passwordItems, passwordItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (row.readTable(vaultItems), row.readTable(passwordItems)),
          )
          .toList(),
    );
  }

  /// Создать новый пароль (vault_items + password_items)
  Future<String> createPassword(CreatePasswordDto dto) {
    final uuid = const Uuid().v4();
    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(uuid),
          type: VaultItemType.password,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );
      await into(passwordItems).insert(
        PasswordItemsCompanion.insert(
          itemId: uuid,
          password: dto.password,
          login: Value(dto.login),
          email: Value(dto.email),
          url: Value(dto.url),
        ),
      );
      await db.vaultItemDao.insertTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  /// Обновить пароль (vault_items + password_items)
  Future<bool> updatePassword(String id, UpdatePasswordDto dto) {
    return db.transaction(() async {
      // Обновляем vault_items
      final vaultCompanion = VaultItemsCompanion(
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isArchived: dto.isArchived != null
            ? Value(dto.isArchived!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );
      await (update(
        vaultItems,
      )..where((v) => v.id.equals(id))).write(vaultCompanion);

      // Обновляем password_items
      final pwCompanion = PasswordItemsCompanion(
        password: dto.password != null
            ? Value(dto.password!)
            : const Value.absent(),
        login: Value(dto.login),
        email: Value(dto.email),
        url: Value(dto.url),
      );
      await (update(
        passwordItems,
      )..where((p) => p.itemId.equals(id))).write(pwCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }
      return true;
    });
  }

  /// Получить только пароль (encrypted field)
  Future<String?> getPasswordFieldById(String id) async {
    final query = selectOnly(passwordItems)
      ..addColumns([passwordItems.password])
      ..where(passwordItems.itemId.equals(id));
    final result = await query.getSingleOrNull();
    return result?.read(passwordItems.password);
  }
}
