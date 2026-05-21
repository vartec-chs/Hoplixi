import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/contact_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class ContactRepository {
  final VaultDB db;

  ContactRepository(this.db);

  AsyncDbResult<String> create(CreateContactDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db
            .into(db.vaultItems)
            .insert(
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

        await db
            .into(db.contactItems)
            .insert(
              ContactItemsCompanion.insert(
                itemId: itemId,
                firstName: dto.contact.firstName,
                middleName: Value(dto.contact.middleName),
                lastName: Value(dto.contact.lastName),
                company: Value(dto.contact.company),
                jobTitle: Value(dto.contact.jobTitle),
                email: Value(dto.contact.email),
                phone: Value(dto.contact.phone),
                address: Value(dto.contact.address),
                website: Value(dto.contact.website),
                birthday: Value(dto.contact.birthday),
                isEmergencyContact: Value(dto.contact.isEmergencyContact),
              ),
            );

        return itemId;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchContactDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = dto.item.itemId;

        final itemUpdated =
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

        if (itemUpdated == 0) {
          throw DBCoreError.notFound(entity: 'vault_items', id: itemId);
        }

        await (db.update(
          db.contactItems,
        )..where((tbl) => tbl.itemId.equals(itemId))).write(
          ContactItemsCompanion(
            firstName: dto.contact.firstName.toRequiredValue(),
            middleName: dto.contact.middleName.toNullableValue(),
            lastName: dto.contact.lastName.toNullableValue(),
            company: dto.contact.company.toNullableValue(),
            jobTitle: dto.contact.jobTitle.toNullableValue(),
            email: dto.contact.email.toNullableValue(),
            phone: dto.contact.phone.toNullableValue(),
            address: dto.contact.address.toNullableValue(),
            website: dto.contact.website.toNullableValue(),
            birthday: dto.contact.birthday.toNullableValue(),
            isEmergencyContact: dto.contact.isEmergencyContact
                .toRequiredValue(),
          ),
        );

        final tagsUpdate = dto.tags;
        if (tagsUpdate is FieldUpdateSet<List<String>>) {
          await db.itemTagsDao.removeAllTagsFromItem(itemId);
          for (final tagId in tagsUpdate.value ?? []) {
            await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          }
        }
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<ContactViewDto>> getViewById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.contactItems,
                  db.contactItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(db.vaultItems.type.equalsValue(VaultItemType.contact));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final contact = row.readTable(db.contactItems);

        return Some(
          ContactViewDto(
            item: item.toVaultItemViewDto(),
            contact: contact.toContactDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<ContactCardDto>> getCardById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.contact));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<ContactCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.contact))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка контактов',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePermanently(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final rows = await (db.delete(
          db.vaultItems,
        )..where((tbl) => tbl.id.equals(itemId))).go();
        if (rows == 0) {
          throw DBCoreError.notFound(entity: 'vault_items', id: itemId);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при удалении контакта',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery() {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.contactItems,
        db.contactItems.itemId.equalsExp(db.vaultItems.id),
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
      db.contactItems.firstName,
      db.contactItems.middleName,
      db.contactItems.lastName,
      db.contactItems.company,
      db.contactItems.email,
      db.contactItems.phone,
      db.contactItems.isEmergencyContact,
    ]);
  }

  ContactCardDto _mapRowToCardDto(TypedResult row) {
    return ContactCardDto(
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
      contact: ContactCardDataDto(
        firstName: row.read(db.contactItems.firstName)!,
        middleName: row.read(db.contactItems.middleName),
        lastName: row.read(db.contactItems.lastName),
        company: row.read(db.contactItems.company),
        email: row.read(db.contactItems.email),
        phone: row.read(db.contactItems.phone),
        isEmergencyContact: row.read(db.contactItems.isEmergencyContact)!,
      ),
    );
  }
}
