import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/mappers/identity_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class IdentityRepository {
  final MainStore db;

  IdentityRepository(this.db);

  Future<String> create(CreateIdentityDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db
          .into(db.vaultItems)
          .insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.identity,
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
          .into(db.identityItems)
          .insert(
            IdentityItemsCompanion.insert(
              itemId: itemId,
              firstName: Value(dto.identity.firstName),
              middleName: Value(dto.identity.middleName),
              lastName: Value(dto.identity.lastName),
              displayName: Value(dto.identity.displayName),
              username: Value(dto.identity.username),
              email: Value(dto.identity.email),
              phone: Value(dto.identity.phone),
              address: Value(dto.identity.address),
              birthday: Value(dto.identity.birthday),
              company: Value(dto.identity.company),
              jobTitle: Value(dto.identity.jobTitle),
              website: Value(dto.identity.website),
              taxId: Value(dto.identity.taxId),
              nationalId: Value(dto.identity.nationalId),
              passportNumber: Value(dto.identity.passportNumber),
              driverLicenseNumber: Value(dto.identity.driverLicenseNumber),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateIdentityDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(
        db.vaultItems,
      )..where((tbl) => tbl.id.equals(itemId))).write(
        VaultItemsCompanion(
          name: Value(dto.item.name),
          description: Value(dto.item.description),
          categoryId: Value(dto.item.categoryId),
          iconRefId: Value(dto.item.iconRefId),
          isFavorite: Value(dto.item.isFavorite),
          isPinned: Value(dto.item.isPinned),
          modifiedAt: Value(now),
        ),
      );

      await (db.update(
        db.identityItems,
      )..where((tbl) => tbl.itemId.equals(itemId))).write(
        IdentityItemsCompanion(
          firstName: Value(dto.identity.firstName),
          middleName: Value(dto.identity.middleName),
          lastName: Value(dto.identity.lastName),
          displayName: Value(dto.identity.displayName),
          username: Value(dto.identity.username),
          email: Value(dto.identity.email),
          phone: Value(dto.identity.phone),
          address: Value(dto.identity.address),
          birthday: Value(dto.identity.birthday),
          company: Value(dto.identity.company),
          jobTitle: Value(dto.identity.jobTitle),
          website: Value(dto.identity.website),
          taxId: Value(dto.identity.taxId),
          nationalId: Value(dto.identity.nationalId),
          passportNumber: Value(dto.identity.passportNumber),
          driverLicenseNumber: Value(dto.identity.driverLicenseNumber),
        ),
      );
    });
  }

  Future<IdentityViewDto?> getViewById(String itemId) async {
    final query =
        db.select(db.vaultItems).join([
            innerJoin(
              db.identityItems,
              db.identityItems.itemId.equalsExp(db.vaultItems.id),
            ),
          ])
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.identity));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final identity = row.readTable(db.identityItems);

    return IdentityViewDto(
      item: item.toVaultItemViewDto(),
      identity: identity.toIdentityDataDto(),
    );
  }

  Future<IdentityCardDto?> getCardById(String itemId) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.identity));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row);
  }

  Future<List<IdentityCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.type.equalsValue(VaultItemType.identity))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapRowToCardDto).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(
      db.vaultItems,
    )..where((tbl) => tbl.id.equals(itemId))).go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.identityItems,
        db.identityItems.itemId.equalsExp(db.vaultItems.id),
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

      db.identityItems.displayName,
      db.identityItems.username,
      db.identityItems.email,
      db.identityItems.phone,
      db.identityItems.company,
    ]);
  }

  IdentityCardDto _mapRowToCardDto(TypedResult row) {
    return IdentityCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.readWithConverter(db.vaultItems.type)!,
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
      identity: IdentityCardDataDto(
        displayName: row.read(db.identityItems.displayName),
        username: row.read(db.identityItems.username),
        email: row.read(db.identityItems.email),
        phone: row.read(db.identityItems.phone),
        company: row.read(db.identityItems.company),
      ),
    );
  }
}
