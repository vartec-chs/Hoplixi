import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../main_store.dart';
import '../models/dto/contact_dto.dart';
import '../models/mappers/contact_mapper.dart';
import '../models/mappers/vault_item_mapper.dart';
import '../tables/vault_items/vault_items.dart';

class ContactRepository {
  final MainStore db;

  ContactRepository(this.db);

  Future<String> create(CreateContactDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.contact,
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

      await db.into(db.contactItems).insert(
            ContactItemsCompanion.insert(
              itemId: itemId,
              firstName: Value(dto.contact.firstName),
              lastName: Value(dto.contact.lastName),
              middleName: Value(dto.contact.middleName),
              organization: Value(dto.contact.organization),
              jobTitle: Value(dto.contact.jobTitle),
              email: Value(dto.contact.email),
              phone: Value(dto.contact.phone),
              address: Value(dto.contact.address),
              website: Value(dto.contact.website),
              birthday: Value(dto.contact.birthday),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateContactDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
          .write(
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

      await (db.update(db.contactItems)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        ContactItemsCompanion(
          firstName: Value(dto.contact.firstName),
          lastName: Value(dto.contact.lastName),
          middleName: Value(dto.contact.middleName),
          organization: Value(dto.contact.organization),
          jobTitle: Value(dto.contact.jobTitle),
          email: Value(dto.contact.email),
          phone: Value(dto.contact.phone),
          address: Value(dto.contact.address),
          website: Value(dto.contact.website),
          birthday: Value(dto.contact.birthday),
        ),
      );
    });
  }

  Future<ContactViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.contactItems,
        db.contactItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.contact));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final contact = row.readTable(db.contactItems);

    return ContactViewDto(
      item: item.toVaultItemViewDto(),
      contact: contact.toContactDataDto(),
    );
  }

  Future<ContactCardDto?> getCardById(String itemId) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.contact));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row);
  }

  Future<List<ContactCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _buildCardQuery()
      ..where(db.vaultItems.type.equalsValue(VaultItemType.contact))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_mapRowToCardDto).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.contactItems,
        db.contactItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..addColumns([
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

        db.contactItems.firstName,
        db.contactItems.lastName,
        db.contactItems.organization,
        db.contactItems.email,
        db.contactItems.phone,
      ]);
  }

  ContactCardDto _mapRowToCardDto(TypedResult row) {
    return ContactCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.read(db.vaultItems.type)!,
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
      contact: ContactCardDataDto(
        firstName: row.read(db.contactItems.firstName),
        lastName: row.read(db.contactItems.lastName),
        organization: row.read(db.contactItems.organization),
        email: row.read(db.contactItems.email),
        phone: row.read(db.contactItems.phone),
      ),
    );
  }
}
