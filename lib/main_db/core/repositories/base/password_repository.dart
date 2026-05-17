import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/mappers/password_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class PasswordRepository {
  final MainStore db;

  PasswordRepository(this.db);

  Future<String> create(CreatePasswordDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db
          .into(db.vaultItems)
          .insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.password,
              name: dto.item.name,
              description: Value(dto.item.description),
              categoryId: Value(dto.item.categoryId),
              iconRefId: Value(dto.item.iconRefId),
              isFavorite: Value(dto.item.isFavorite),
              isPinned: Value(dto.item.isPinned),
              createdAt: Value(now),
              modifiedAt: Value(now),
            ),
          );

      await db
          .into(db.passwordItems)
          .insert(
            PasswordItemsCompanion.insert(
              itemId: itemId,
              login: Value(dto.password.login),
              email: Value(dto.password.email),
              password: dto.password.password,
              url: Value(dto.password.url),
              expiresAt: Value(dto.password.expiresAt),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(PatchPasswordDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(
        db.vaultItems,
      )..where((tbl) => tbl.id.equals(itemId))).write(
        VaultItemsCompanion(
          name: dto.item.name.toRequiredValue(),
          description: dto.item.description.toNullableValue(),
          categoryId: dto.item.categoryId.toNullableValue(),
          iconRefId: dto.item.iconRefId.toNullableValue(),
          isFavorite: dto.item.isFavorite.toRequiredValue(),
          isPinned: dto.item.isPinned.toRequiredValue(),
          modifiedAt: Value(now),
        ),
      );

      await (db.update(
        db.passwordItems,
      )..where((tbl) => tbl.itemId.equals(itemId))).write(
        PasswordItemsCompanion(
          login: dto.password.login.toNullableValue(),
          email: dto.password.email.toNullableValue(),
          password: dto.password.password.toRequiredValue(),
          url: dto.password.url.toNullableValue(),
          expiresAt: dto.password.expiresAt.toNullableValue(),
        ),
      );
    });
  }

  Future<PasswordViewDto?> getViewById(String itemId) async {
    final query =
        db.select(db.vaultItems).join([
            innerJoin(
              db.passwordItems,
              db.passwordItems.itemId.equalsExp(db.vaultItems.id),
            ),
          ])
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.password));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final password = row.readTable(db.passwordItems);

    return PasswordViewDto(
      item: item.toVaultItemViewDto(),
      password: password.toPasswordDataDto(),
    );
  }

  Future<PasswordCardDto?> getCardById(String itemId) async {
    final expr = _PasswordCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.password));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<PasswordCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final expr = _PasswordCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.password))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(
      db.vaultItems,
    )..where((tbl) => tbl.id.equals(itemId))).go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _PasswordCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.passwordItems,
        db.passwordItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])..addColumns([
      db.vaultItems.id,
      db.vaultItems.type,
      db.vaultItems.name,
      db.vaultItems.description,
      db.vaultItems.categoryId,
      db.vaultItems.iconRefId,
      db.vaultItems.isFavorite,
      db.vaultItems.isArchived,
      db.vaultItems.isPinned,
      db.vaultItems.isDeleted,
      db.vaultItems.createdAt,
      db.vaultItems.modifiedAt,
      db.vaultItems.lastUsedAt,
      db.vaultItems.archivedAt,
      db.vaultItems.deletedAt,
      db.vaultItems.recentScore,
      db.passwordItems.login,
      db.passwordItems.email,
      db.passwordItems.url,
      db.passwordItems.expiresAt,
      expr.hasPassword,
    ]);
  }

  PasswordCardDto _mapRowToCardDto(
    TypedResult row,
    _PasswordCardExpressions expr,
  ) {
    return PasswordCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.readWithConverter<VaultItemType, String>(db.vaultItems.type)!,
        name: row.read(db.vaultItems.name)!,
        description: row.read(db.vaultItems.description),
        categoryId: row.read(db.vaultItems.categoryId),
        iconRefId: row.read(db.vaultItems.iconRefId),
        isFavorite: row.read(db.vaultItems.isFavorite)!,
        isArchived: row.read(db.vaultItems.isArchived)!,
        isPinned: row.read(db.vaultItems.isPinned)!,
        isDeleted: row.read(db.vaultItems.isDeleted)!,
        createdAt: row.read(db.vaultItems.createdAt)!,
        modifiedAt: row.read(db.vaultItems.modifiedAt)!,
        lastUsedAt: row.read(db.vaultItems.lastUsedAt),
        archivedAt: row.read(db.vaultItems.archivedAt),
        deletedAt: row.read(db.vaultItems.deletedAt),
        recentScore: row.read(db.vaultItems.recentScore),
      ),
      password: PasswordCardDataDto(
        login: row.read(db.passwordItems.login),
        email: row.read(db.passwordItems.email),
        url: row.read(db.passwordItems.url),
        expiresAt: row.read(db.passwordItems.expiresAt),
        hasPassword: row.read(expr.hasPassword) ?? false,
      ),
    );
  }
}

class _PasswordCardExpressions {
  _PasswordCardExpressions(this.db)
    : hasPassword = db.passwordItems.password.isNotNull();

  final MainStore db;
  final Expression<bool> hasPassword;
}
