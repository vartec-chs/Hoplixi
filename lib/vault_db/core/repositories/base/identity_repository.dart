import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/identity_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class IdentityRepository {
  final VaultDB db;

  IdentityRepository(this.db);

  AsyncDbResult<String> create(CreateIdentityDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
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

        
        if (dto.tagIds.isNotEmpty) {
          for (final tagId in dto.tagIds) {
            await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          }
        }

        return itemId;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании идентификатора',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchIdentityDto dto) {
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
          db.identityItems,
        )..where((tbl) => tbl.itemId.equals(itemId))).write(
          IdentityItemsCompanion(
            firstName: dto.identity.firstName.toNullableValue(),
            middleName: dto.identity.middleName.toNullableValue(),
            lastName: dto.identity.lastName.toNullableValue(),
            displayName: dto.identity.displayName.toNullableValue(),
            username: dto.identity.username.toNullableValue(),
            email: dto.identity.email.toNullableValue(),
            phone: dto.identity.phone.toNullableValue(),
            address: dto.identity.address.toNullableValue(),
            birthday: dto.identity.birthday.toNullableValue(),
            company: dto.identity.company.toNullableValue(),
            jobTitle: dto.identity.jobTitle.toNullableValue(),
            website: dto.identity.website.toNullableValue(),
            taxId: dto.identity.taxId.toNullableValue(),
            nationalId: dto.identity.nationalId.toNullableValue(),
            passportNumber: dto.identity.passportNumber.toNullableValue(),
            driverLicenseNumber: dto.identity.driverLicenseNumber
                .toNullableValue(),
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
              message: 'Ошибка при обновлении идентификатора',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<IdentityViewDto>> getViewById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
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
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final identity = row.readTable(db.identityItems);

        return Some(
          IdentityViewDto(
            item: item.toVaultItemViewDto(),
            identity: identity.toIdentityDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении идентификатора',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<IdentityCardDto>> getCardById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.identity));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки идентификатора',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<IdentityCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query = _buildCardQuery()
          ..where(db.vaultItems.type.equalsValue(VaultItemType.identity))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map(_mapRowToCardDto).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка идентификаторов',
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
              message: 'Ошибка при удалении идентификатора',
              cause: e,
              stackTrace: st,
            ),
    );
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
